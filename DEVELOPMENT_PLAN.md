# Plan de Développement - ESTIM Campus

Ce document détaille les phases de conception et de développement de l'application ESTIM Campus, incluant la version actuelle et le plan de reconstruction en Django pur.

## 1. Plan de Base (Version Actuelle)
### Architecture
- **Frontend :** Mobile Flutter (Android/iOS)
- **Backend :** Django REST Framework (API)
- **Base de données :** PostgreSQL / SQLite (développement)
- **Stockage :** Media local / Serveur statique

### Fonctionnalités Clés
- Inscription en ligne des étudiants.
- Consultation des emplois du temps (EDT).
- Consultation des résultats d'examens.
- Système de notifications pour les annonces.
- Génération de fiches d'inscription en PDF via ReportLab.

## 2. Plan de Reconstruction en Django Pur
### Objectif
Migrer l'interface utilisateur du mobile (Flutter) vers une application Web responsive utilisant uniquement les outils natifs de Django (Templates, Forms, Views).

### Étapes de Conception
1. **Migration de l'UI :**
   - Conversion des widgets Flutter en templates HTML5/CSS3.
   - Utilisation de CSS Vanilla pour garantir la légèreté et la rapidité.
   - Design "Mobile-First" pour conserver l'expérience utilisateur actuelle.

2. **Refactorisation de la Logique :**
   - Remplacement des `ViewSets` DRF par des `Views` Django classiques.
   - Utilisation de `django.forms` pour la validation et le rendu des formulaires.
   - Gestion de l'authentification via le middleware de session Django.

3. **Optimisation de l'Inscription :**
   - Ajout d'une capture photo en direct via JavaScript (API MediaDevices).
   - Validation de la clarté de l'image côté client avant soumission.
   - Intégration de la photo dans le document PDF généré.

4. **Gestion Documentaire :**
   - Ajout de mentions spécifiques sur les documents PDF ("À IMPRIMER DANS INSCRIPTION").
   - Automatisation de l'archivage des fiches d'inscription.

### Schéma de Données (Inscription)
Le modèle `Inscription` a été mis à jour pour inclure :
- `photo` : Image d'identité de l'étudiant.
- Champs d'identité, d'études antérieures et de choix de formation.

## 3. Mise en Œuvre Technique (Inscription)
### Formulaire avec Photo
Le nouveau formulaire d'inscription place la photo au tout début. Un script JavaScript gère :
- L'activation de la caméra.
- La prise de photo.
- La vérification visuelle (recharge automatique si non satisfaisant).

### PDF de Sortie
Le document PDF généré inclura désormais :
- La photo de l'étudiant en haut à droite.
- Le texte "À IMPRIMER DANS INSCRIPTION" en filigrane ou en pied de page.
