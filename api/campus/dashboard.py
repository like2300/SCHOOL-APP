"""Callback officiel du tableau de bord Unfold (UNFOLD["DASHBOARD_CALLBACK"]).

Conforme à https://unfoldadmin.com/docs/configuration/dashboard/
Injecte les données ESTIM dans templates/admin/index.html via `dashboard`.
"""

from .templatetags.campus_stats import (
    barres_6mois,
    chart_inscriptions_mois,
    chart_inscriptions_statuts,
    chart_paiements_mois,
    chart_top_filieres,
    cours_aujourdhui,
    dashboard_cards,
    dernieres_inscriptions,
    derniers_paiements,
)


def dashboard_callback(request, context):
    context.update(
        {
            "dashboard": {
                "cards": dashboard_cards(),
                "charts": {
                    "ins_mois": chart_inscriptions_mois(),
                    "ins_statuts": chart_inscriptions_statuts(),
                    "pay_mois": chart_paiements_mois(),
                    "filieres": chart_top_filieres(),
                },
                "barres": barres_6mois(),
                "paiements": derniers_paiements(6),
                "inscriptions": dernieres_inscriptions(5),
                "cours_jour": cours_aujourdhui(),
            }
        }
    )
    return context
