import os

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Crée le superuser root (mot de passe 'root' par défaut) s'il n'existe pas."

    def handle(self, *args, **opts):
        username = os.getenv("DJANGO_SUPERUSER_USERNAME", "root")
        password = os.getenv("DJANGO_SUPERUSER_PASSWORD", "root")
        email = os.getenv("DJANGO_SUPERUSER_EMAIL", "root@estim-campus.local")

        user, created = User.objects.get_or_create(
            username=username,
            defaults={"email": email, "is_staff": True, "is_superuser": True},
        )
        if created:
            user.set_password(password)
            user.is_staff = True
            user.is_superuser = True
            user.save()
            self.stdout.write(self.style.SUCCESS(
                f"Superuser '{username}' créé (mot de passe par défaut : '{password}')."
            ))
        else:
            self.stdout.write(f"Superuser '{username}' existe déjà — rien à faire.")
