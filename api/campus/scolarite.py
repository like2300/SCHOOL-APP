"""Helpers scolarité : affiliation étudiant, périodes d'année, statuts de dette."""

import calendar
from datetime import date
from decimal import Decimal


def match_affiliation(choix_cycle, choix_filiere, niveaux=None, filieres=None):
    """Retrouve (Niveau, Filiere) depuis les textes d'une fiche d'inscription."""
    from .models import Filiere, Niveau

    if niveaux is None:
        niveaux = list(Niveau.objects.all())
    if filieres is None:
        filieres = list(Filiere.objects.all())
    niv = fil = None
    cycle = (choix_cycle or "").upper()
    for n in niveaux:
        if n.nom and n.nom.upper() in cycle:
            if niv is None or len(n.nom) > len(niv.nom):
                niv = n
    choix = (choix_filiere or "").upper()
    for f in filieres:
        if f.nom and f.nom.upper() in choix:
            if fil is None or len(f.nom) > len(fil.nom):
                fil = f
    return niv, fil


def montant_attendu(niveau, filiere):
    """Montant à payer : tarif (Filière+Niveau) d'abord, sinon filière, sinon 0."""
    from .models import TarifScolarite

    if niveau and filiere:
        try:
            tarif = TarifScolarite.objects.filter(niveau=niveau, filiere=filiere).first()
            if tarif and tarif.montant:
                return tarif.montant
        except Exception:
            pass
    if filiere and getattr(filiere, 'montant_scolarite', None):
        return filiere.montant_scolarite
    return Decimal("0")


def periode_annee(annee):
    """Période (début, fin) d'une année académique depuis mois début/fin.
    Ex : 2025-2026, début=10, fin=6 -> 01/10/2025 au 30/06/2026."""
    if not annee:
        return None, None
    try:
        start_year = int(str(annee.nom).split("-")[0])
    except (ValueError, IndexError):
        return None, None
    debut = date(start_year, annee.mois_debut, 1)
    end_year = start_year + 1 if annee.mois_fin < annee.mois_debut else start_year
    fin = date(end_year, annee.mois_fin, calendar.monthrange(end_year, annee.mois_fin)[1])
    return debut, fin


def statut_dette(attendu, paye):
    """PAYE / PARTIEL / IMPAYE / SANS_TARIF + reste."""
    attendu = attendu or Decimal("0")
    paye = paye or Decimal("0")
    reste = attendu - paye
    if attendu <= 0:
        return "SANS_TARIF", Decimal("0")
    if reste <= 0:
        return "PAYE", Decimal("0")
    if paye > 0:
        return "PARTIEL", reste
    return "IMPAYE", reste


def mois_annee_academique(annee):
    """Mois couverts par l'année académique, dans l'ordre : [(num, annee_civile, label)].

    Ex : début=10, fin=6, nom=2025-2026 -> Oct 2025 … Juin 2026.
    Utilisé pour le dropdown 'Mois concerné' du paiement (jusqu'au dernier mois en DB).
    """
    NOMS = {1: "Janvier", 2: "Février", 3: "Mars", 4: "Avril",
            5: "Mai", 6: "Juin", 7: "Juillet", 8: "Août",
            9: "Septembre", 10: "Octobre", 11: "Novembre", 12: "Décembre"}
    if not annee:
        return []
    try:
        start_year = int(str(annee.nom).split("-")[0])
    except (ValueError, IndexError):
        return []
    out = []
    m, y = annee.mois_debut, start_year
    for _ in range(24):  # sécurité anti-boucle
        out.append((m, y, f"{NOMS.get(m, m)} {y}"))
        if m == annee.mois_fin:
            break
        m = m % 12 + 1
        if m == 1:
            y += 1
    return out


STATUT_LABELS = {
    "PAYE": "Payé",
    "PARTIEL": "Partiel",
    "IMPAYE": "Non payé",
    "SANS_TARIF": "Sans tarif",
}
