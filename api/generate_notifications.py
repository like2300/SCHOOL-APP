#!/usr/bin/env python3
"""
Script pour générer des notifications générales (sans target_matricule)
à partir des annonces, cours, examens et calendrier déjà existants en base.

À exécuter UNE FOIS après le déploiement des corrections du backend,
pour que les utilisateurs voient des notifications immédiatement.

Exécuter avec:
    python manage.py shell < generate_notifications.py
OU
    python generate_notifications.py
"""

import os
import sys

import django

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "estim_campus_api.settings")
django.setup()

from campus.models import (
    Annonce,
    CalendrierAcademique,
    Cours,
    Examen,
    Notification,
)

print("=" * 70)
print(" GÉNÉRATION DE NOTIFICATIONS GÉNÉRALES ")
print("=" * 70)

created = 0

# --- Annonces existantes sans notification associée ---
for annonce in Annonce.objects.all():
    already = Notification.objects.filter(
        notification_type="annonce", related_id=annonce.id
    ).exists()
    if already:
        continue
    Notification.objects.create(
        title=f"📣 {annonce.title}",
        message=(annonce.description[:200] if annonce.description else ""),
        notification_type="annonce",
        related_id=annonce.id,
        annonce=annonce,
    )
    created += 1
    print(f"  + Annonce: {annonce.title}")

# --- Cours existants ---
for cours in Cours.objects.all():
    already = Notification.objects.filter(
        notification_type="cours", related_id=cours.id
    ).exists()
    if already:
        continue
    Notification.objects.create(
        title=f"📚 Nouveau cours: {cours.matiere}",
        message=f"{cours.matiere} avec {cours.prof} en salle {cours.salle}.",
        notification_type="cours",
        related_id=cours.id,
    )
    created += 1
    print(f"  + Cours: {cours.matiere}")

# --- Examens existants ---
for examen in Examen.objects.all():
    already = Notification.objects.filter(
        notification_type="examen", related_id=examen.id
    ).exists()
    if already:
        continue
    Notification.objects.create(
        title=f"📝 {examen.type}: {examen.matiere}",
        message=(
            f"{examen.type} de {examen.matiere} prévu le "
            f"{examen.date} à {examen.heure} en salle {examen.salle}."
        ),
        notification_type="examen",
        related_id=examen.id,
    )
    created += 1
    print(f"  + Examen: {examen.matiere}")

# --- Calendrier existant ---
for event in CalendrierAcademique.objects.all():
    already = Notification.objects.filter(
        notification_type="calendrier", related_id=event.id
    ).exists()
    if already:
        continue
    Notification.objects.create(
        title=f"📅 {event.title}",
        message=(event.description[:200] if event.description else ""),
        notification_type="calendrier",
        related_id=event.id,
    )
    created += 1
    print(f"  + Calendrier: {event.title}")

print("=" * 70)
print(f" Total: {created} notifications générales créées")
print("=" * 70)

total = Notification.objects.count()
print(f"Total notifications en base: {total}")
print("=" * 70)
