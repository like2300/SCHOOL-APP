"""Envoi de messages au tuteur via l'API WhatsApp/SMS + garde-fous anti-blocage.

Règles appliquées pour ne pas être bloqué :
- numéro normalisé au format international 242 obligatoire ;
- délai minimum entre deux envois (WHATSAPP_MIN_DELAY_SECONDS, défaut 5 s) ;
- quota journalier max (WHATSAPP_DAILY_LIMIT, défaut 500) ;
- timeout court, aucun crash : tout échec est journalisé dans MessageLog.
"""

import re
import time

import requests
from django.conf import settings
from django.utils import timezone


def normalize_number(raw):
    """Normalise un numéro au format 242 + 9 chiffres (le 0 local est conservé).
    Ex : 061167676 -> 242061167676. Retourne None si invalide."""
    digits = re.sub(r"\D", "", str(raw or ""))
    if digits.startswith("00"):
        digits = digits[2:]
    if digits.startswith("242"):
        rest = digits[3:]
        if len(rest) == 9:
            digits = "242" + rest
        elif len(rest) == 8:
            digits = "2420" + rest  # 0 local manquant
        else:
            return None
    elif digits.startswith("0") and len(digits) == 9:
        digits = "242" + digits
    elif digits.startswith("0") and len(digits) == 10:
        digits = "242" + digits[1:]
    elif len(digits) == 8:
        digits = "2420" + digits  # 0 local manquant
    else:
        return None
    if re.fullmatch(r"242\d{9}", digits):
        return digits
    return None
    if re.fullmatch(r"242\d{9}", digits):
        return digits
    return None


def _log(to, message, status, response=""):
    from .models import MessageLog

    try:
        MessageLog.objects.create(
            to=to or "",
            message=(message or "")[:2000],
            status=status,
            response=(response or "")[:2000],
        )
    except Exception:
        pass


def resolve_ecole(paiement):
    """Nom de l'école : celle choisie dans la fiche d'inscription de l'élève.

    - matricule INS-<id> : inscription directe ;
    - sinon : recherche de l'inscription par le nom de l'élève ;
    - repli : premier établissement configuré, sinon "ESTIM".
    """
    try:
        from inscription.models import Inscription
        from .models import Etablissement

        mat = (paiement.matricule or "").strip()
        ins = None
        if mat.upper().startswith("INS-"):
            try:
                ins = Inscription.objects.filter(pk=int(mat.split("-", 1)[1])).first()
            except (ValueError, IndexError):
                ins = None
        if ins is None and paiement.nom_etudiant:
            parts = paiement.nom_etudiant.split()
            if len(parts) >= 2:
                ins = Inscription.objects.filter(
                    last_name__icontains=parts[0], first_name__icontains=parts[-1]
                ).first()
            elif parts:
                ins = Inscription.objects.filter(last_name__icontains=parts[0]).first()
        if ins and ins.target_etablissement:
            return ins.target_etablissement
        etab = Etablissement.objects.order_by("nom").first()
        if etab:
            return etab.nom
    except Exception:
        pass
    return "ESTIM"


def build_recu_message(paiement):
    """Reçu SMS épuré, style facture — mois payé, reste dû et signature école."""
    from decimal import Decimal

    from django.db.models import Sum

    from .models import PaiementScolarite
    from .scolarite import montant_attendu

    ecole = resolve_ecole(paiement)

    def fmt(m):
        try:
            return f"{float(m):,.0f}".replace(",", " ")
        except (TypeError, ValueError):
            return m

    lignes = [
        f"{ecole}",
        f"— Reçu {paiement.reference or ''}",
        f"Élève : {paiement.nom_etudiant} ({paiement.matricule})",
    ]
    # Mois de scolarité couvert par ce paiement
    mois_nom = ""
    if getattr(paiement, "mois", None):
        mois_nom = dict(MOIS_NOMS).get(int(paiement.mois), "")
    if mois_nom:
        lignes.append(f"Mois payé : {mois_nom}")
    lignes.append(f"Motif : {paiement.get_motif_display()} — {fmt(paiement.montant)} FCFA")

    # Dette restante sur le tarif (attendu − total payé du matricule)
    try:
        attendu = montant_attendu(paiement.niveau, paiement.filiere) or Decimal("0")
        paye = PaiementScolarite.objects.filter(matricule=paiement.matricule).aggregate(
            t=Sum("montant")
        )["t"] or Decimal("0")
        reste = attendu - paye
        if attendu > 0 and reste > 0:
            lignes.append(f"Reste dû : {fmt(reste)} FCFA")
        elif attendu > 0:
            lignes.append("Scolarité soldée. Merci !")
    except Exception:
        pass

    lignes.append(f"{ecole} vous remercie.")
    return "\n".join(lignes)


MOIS_NOMS = [
    (1, "Janvier"), (2, "Février"), (3, "Mars"), (4, "Avril"),
    (5, "Mai"), (6, "Juin"), (7, "Juillet"), (8, "Août"),
    (9, "Septembre"), (10, "Octobre"), (11, "Novembre"), (12, "Décembre"),
]


def send_tutor_message(to, message):
    """Envoie un message au tuteur. Ne lève jamais d'exception. Retourne True/False."""
    from .models import MessageLog

    if not getattr(settings, "WHATSAPP_ENABLED", True):
        _log(to, message, "SKIPPED", "WHATSAPP_ENABLED=False")
        return False
    if not message:
        return False

    numero = normalize_number(to)
    if not numero:
        _log(to, message, "SKIPPED", "Numéro invalide (format 242 obligatoire)")
        return False

    token = getattr(settings, "WHATSAPP_API_TOKEN", "")
    base_url = getattr(settings, "WHATSAPP_API_URL", "https://omerlinkchat.alwaysdata.net/api/send")
    if not token:
        _log(numero, message, "SKIPPED", "Token API manquant")
        return False

    min_delay = int(getattr(settings, "WHATSAPP_MIN_DELAY_SECONDS", 5))
    daily_limit = int(getattr(settings, "WHATSAPP_DAILY_LIMIT", 500))
    timeout = int(getattr(settings, "WHATSAPP_TIMEOUT", 10))

    try:
        today = timezone.now().date()
        sent_today = MessageLog.objects.filter(status="SUCCESS", created_at__date=today).count()
        if sent_today >= daily_limit:
            _log(numero, message, "SKIPPED", f"Quota journalier atteint ({daily_limit})")
            return False

        last = MessageLog.objects.filter(status="SUCCESS").order_by("-created_at").first()
        if last:
            elapsed = (timezone.now() - last.created_at).total_seconds()
            if elapsed < min_delay:
                time.sleep(min_delay - elapsed)

        resp = requests.get(
            base_url,
            params={"token": token, "to": numero, "message": message},
            timeout=timeout,
        )
        body = resp.text or ""
        ok = False
        try:
            ok = bool(resp.json().get("ok")) and resp.status_code == 200
        except Exception:
            ok = resp.status_code == 200 and "error" not in body[:500].lower()
        _log(numero, message, "SUCCESS" if ok else "FAILED", f"HTTP {resp.status_code} : {body[:1500]}")
        return ok
    except Exception as e:
        _log(numero, message, "FAILED", f"Exception : {e}")
        return False
