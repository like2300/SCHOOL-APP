"""Tags du tableau de bord d'accueil admin (cartes + graphiques)."""

from datetime import date

from django import template
from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth

register = template.Library()

MOIS_FR = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"]


def _12_mois():
    today = date.today()
    mois = []
    y, m = today.year, today.month
    for _ in range(12):
        mois.append((y, m))
        m -= 1
        if m == 0:
            m, y = 12, y - 1
    return list(reversed(mois))


@register.simple_tag
def dashboard_cards():
    from campus.models import Employe, PaiementScolarite
    from inscription.models import Inscription

    total_ins = Inscription.objects.count()
    validees = Inscription.objects.filter(statut="VALIDEE").count()
    attente = Inscription.objects.filter(statut="EN_ATTENTE").count()
    rejetees = Inscription.objects.filter(statut="REJETEE").count()
    encaisse = PaiementScolarite.objects.aggregate(t=Sum("montant"))["t"] or 0
    nb_paiements = PaiementScolarite.objects.count()
    employes = Employe.objects.filter(statut="ACTIF").count()
    taux_validation = round(validees / total_ins * 100) if total_ins else 0
    return {
        "total_ins": total_ins,
        "validees": validees,
        "attente": attente,
        "rejetees": rejetees,
        "encaisse": encaisse,
        "nb_paiements": nb_paiements,
        "employes": employes,
        "taux_validation": taux_validation,
    }


def _serie_mensuelle(qs, champ_date="created_at"):
    mois = _12_mois()
    labels = [f"{MOIS_FR[m - 1]} {str(y)[2:]}" for y, m in mois]
    data = [0] * 12
    index = {(y, m): i for i, (y, m) in enumerate(mois)}
    for row in qs.annotate(mois=TruncMonth(champ_date)).values("mois").annotate(n=Count("id")).order_by("mois"):
        if row["mois"] and (row["mois"].year, row["mois"].month) in index:
            data[index[(row["mois"].year, row["mois"].month)]] = row["n"]
    return labels, data


@register.simple_tag
def chart_inscriptions_mois():
    from inscription.models import Inscription

    labels, data = _serie_mensuelle(Inscription.objects.all())
    return {"labels": labels, "data": data}


@register.simple_tag
def chart_inscriptions_statuts():
    from inscription.models import Inscription

    rows = Inscription.objects.values("statut").annotate(n=Count("id"))
    mapping = {"VALIDEE": "Validées", "EN_ATTENTE": "En attente", "REJETEE": "Rejetées"}
    labels, data = [], []
    for r in rows:
        labels.append(mapping.get(r["statut"], r["statut"] or "—"))
        data.append(r["n"])
    return {"labels": labels, "data": data}


@register.simple_tag
def chart_paiements_mois():
    from campus.models import PaiementScolarite

    mois = _12_mois()
    labels = [f"{MOIS_FR[m - 1]} {str(y)[2:]}" for y, m in mois]
    data = [0] * 12
    index = {(y, m): i for i, (y, m) in enumerate(mois)}
    for row in (
        PaiementScolarite.objects.annotate(mois_trunc=TruncMonth("created_at"))
        .values("mois_trunc")
        .annotate(t=Sum("montant"))
        .order_by("mois_trunc")
    ):
        if row["mois_trunc"] and (row["mois_trunc"].year, row["mois_trunc"].month) in index:
            data[index[(row["mois_trunc"].year, row["mois_trunc"].month)]] = float(row["t"] or 0)
    return {"labels": labels, "data": data}


@register.simple_tag
def chart_paiements_motifs():
    from campus.models import PaiementScolarite

    labels_map = dict(PaiementScolarite.MOTIF_CHOICES)
    labels, data = [], []
    for r in PaiementScolarite.objects.values("motif").annotate(t=Sum("montant")).order_by("-t"):
        labels.append(labels_map.get(r["motif"], r["motif"] or "—"))
        data.append(float(r["t"] or 0))
    return {"labels": labels, "data": data}


@register.simple_tag
def derniers_paiements(n=6):
    from campus.models import PaiementScolarite

    return list(
        PaiementScolarite.objects.order_by("-created_at").values(
            "matricule", "nom_etudiant", "montant", "motif", "methode", "created_at"
        )[: int(n)]
    )


@register.simple_tag
def dernieres_inscriptions(n=5):
    from inscription.models import Inscription

    return list(
        Inscription.objects.order_by("-created_at").values(
            "last_name", "first_name", "choix_filiere", "statut", "created_at"
        )[: int(n)]
    )


@register.simple_tag
def cours_aujourdhui():
    """Cours du jour (selon le jour de semaine actuel)."""
    from campus.models import Cours

    jour = date.today().isoweekday()  # 1=Lundi … 7=Dimanche
    rows = []
    for c in Cours.objects.select_related("filiere", "niveau").all():
        if jour in c.get_jours_list():
            rows.append(c)
    return rows


@register.simple_tag
def barres_6mois():
    """Encaissements des 6 derniers mois (barres CSS : label, montant, %)."""
    from campus.models import PaiementScolarite

    today = date.today()
    mois = []
    y, m = today.year, today.month
    for _ in range(6):
        mois.append((y, m))
        m -= 1
        if m == 0:
            m, y = 12, y - 1
    mois = list(reversed(mois))
    totaux = {(y, m): 0 for y, m in mois}
    for row in (
        PaiementScolarite.objects.annotate(mois_trunc=TruncMonth("created_at"))
        .values("mois_trunc")
        .annotate(t=Sum("montant"))
    ):
        if row["mois_trunc"] and (row["mois_trunc"].year, row["mois_trunc"].month) in totaux:
            totaux[(row["mois_trunc"].year, row["mois_trunc"].month)] = float(row["t"] or 0)
    maximum = max(totaux.values()) or 1
    return [
        {"label": MOIS_FR[m - 1], "montant": totaux[(y, m)],
         "pct": round(totaux[(y, m)] / maximum * 100)}
        for y, m in mois
    ]


@register.simple_tag
def chart_top_filieres():
    from inscription.models import Inscription

    rows = (
        Inscription.objects.filter(statut="VALIDEE")
        .values("choix_filiere")
        .annotate(n=Count("id"))
        .order_by("-n")[:8]
    )
    return {"labels": [r["choix_filiere"] or "—" for r in rows], "data": [r["n"] for r in rows]}
