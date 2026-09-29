from django.core.management.base import BaseCommand


# Raccourcis affichés dans l'app Flutter (page Applications).
# `route` = route Flutter, `icon_name` = clé reconnue par l'app.
APPS = [
    {"title": "Emploi du temps", "description": "Cours de la semaine par niveau et filière",
     "icon_name": "calendar_today", "route": "/emploi", "image_url": ""},
    {"title": "Résultats", "description": "Consulter les résultats d'examen",
     "icon_name": "grade", "route": "/resultats", "image_url": ""},
    {"title": "Examens", "description": "Calendrier et sessions d'examens",
     "icon_name": "menu_book", "route": "/examens", "image_url": ""},
    {"title": "Annonces", "description": "Actualités et annonces du campus",
     "icon_name": "message", "route": "/annonces", "image_url": ""},
    {"title": "Vérification", "description": "Vérifier une fiche d'inscription",
     "icon_name": "assignment", "route": "/verify", "image_url": ""},
]

# Liens affichés dans l'app (page Sites & Liens utiles).
SITES = [
    {"title": "Portail Inscription", "url": "https://estim-campus.alwaysdata.net/inscription/",
     "icon_name": "how_to_reg"},
    {"title": "Site Officiel ESTIM", "url": "https://estim-ecole.com/",
     "icon_name": "school"},
    {"title": "Facebook ESTIM", "url": "https://www.facebook.com/estim.congo",
     "icon_name": "facebook"},
]


class Command(BaseCommand):
    help = "Ajoute les raccourcis (apps + sites) par défaut s'ils n'existent pas."

    def handle(self, *args, **opts):
        from campus.models import CampusApp, SiteWeb

        n_apps = 0
        for a in APPS:
            _, created = CampusApp.objects.get_or_create(
                title=a["title"],
                defaults={k: v for k, v in a.items() if k != "title"},
            )
            n_apps += created
        n_sites = 0
        for s in SITES:
            _, created = SiteWeb.objects.get_or_create(
                title=s["title"],
                defaults={k: v for k, v in s.items() if k != "title"},
            )
            n_sites += created
        self.stdout.write(self.style.SUCCESS(
            f"Raccourcis OK : +{n_apps} app(s), +{n_sites} site(s)."
        ))
