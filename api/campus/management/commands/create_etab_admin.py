from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User


class Command(BaseCommand):
    help = "Crée un admin restreint à un établissement précis."

    def add_arguments(self, parser):
        parser.add_argument("username", help="Nom d'utilisateur")
        parser.add_argument("etablissement", help="Nom exact de l'établissement")
        parser.add_argument("--password", default=None, help="Mot de passe (sinon demandé)")
        parser.add_argument("--email", default="", help="Email")

    def handle(self, *args, **opts):
        from campus.models import Etablissement, ProfilEtablissement
        from django.contrib.auth.models import Permission

        try:
            etab = Etablissement.objects.get(nom__iexact=opts["etablissement"])
        except Etablissement.DoesNotExist:
            raise CommandError(f"Établissement '{opts['etablissement']}' introuvable.")

        user, created = User.objects.get_or_create(
            username=opts["username"], defaults={"email": opts["email"]},
        )
        pwd = opts["password"] or User.objects.make_random_password()
        user.set_password(pwd)
        user.is_staff = True
        user.is_superuser = False
        user.save()
        # Droits : tout voir/modifier sauf users/groupes/profils (réservés superuser)
        perms = Permission.objects.exclude(
            content_type__app_label__in=("auth", "admin", "contenttypes", "sessions"),
        ).exclude(codename__contains="profil")
        user.user_permissions.set(perms)

        ProfilEtablissement.objects.update_or_create(
            user=user, defaults={"etablissement": etab},
        )
        self.stdout.write(self.style.SUCCESS(
            f"OK : {user.username} → {etab.nom} (mdp: {pwd if not opts['password'] else 'défini'})"
        ))
