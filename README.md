# Estim Campus 🎓

Estim Campus est une application mobile et web moderne conçue pour accompagner les étudiants d'ESTIM dans leur quotidien académique. Elle offre une interface intuitive et responsive pour accéder rapidement à toutes les informations essentielles du campus.

## 🚀 Fonctionnalités Clés

### 📱 Interface Responsive & Moderne
- **Design Adaptatif** : L'application s'adapte automatiquement à votre appareil.
  - **Mobile** : Navigation fluide via une barre de navigation basse.
  - **Tablette & PC** : Sidebar latérale pour une utilisation optimale sur grand écran.
- **Thème Visuel** : Esthétique soignée aux couleurs d'ESTIM (Jaune et Blanc), offrant une expérience utilisateur agréable et professionnelle.

### 📅 Gestion Académique
- **Emploi du Temps** : Consultez vos horaires de cours en temps réel avec une vue chronologique claire.
- **Calendrier des Examens** : Ne manquez aucune épreuve grâce au calendrier dédié, filtrable par jour ou par session.
- **Résultats d'Examens** : Consultez vos notes et votre moyenne générale directement dans l'application via votre matricule (système sécurisé avec support de paiement pour les consultations externes).

### 📢 Information & Communication
- **Annonces en Temps Réel** : Restez informé des dernières nouvelles du campus (événements, cours, changements d'horaires).
- **Notifications Push** : Recevez des alertes instantanées pour les annonces importantes et les mises à jour de l'emploi du temps.
- **Partage Social** : Partagez facilement les annonces importantes avec vos camarades via WhatsApp, Facebook, etc.

### 🛠️ Services Intégrés
- **Portail d'Inscription** : Accès direct au formulaire d'inscription en ligne.
- **Vérification de Statut** : Suivez l'évolution de votre dossier d'inscription.
- **Paiements Sécurisés** : Intégration d'OpenPay pour le règlement des frais de consultation de résultats ou d'inscription.

## 🛠️ Stack Technique

- **Frontend** : [Flutter](https://flutter.dev/) (Dart)
- **Backend** : Django (Python) - API REST
- **Base de données** : PostgreSQL / SQLite (via Django)
- **Services tiers** : 
  - `shared_preferences` pour le stockage local.
  - `flutter_local_notifications` pour les alertes.
  - `url_launcher` & `webview_flutter` pour les interactions web.

## 📦 Installation & Configuration

### Prérequis
- Flutter SDK (dernière version stable)
- Android Studio / VS Code
- Un émulateur ou un appareil physique

### Étapes
1. **Cloner le projet**
   ```bash
   git clone <url-du-depot>
   cd estim_campus
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

## 🏗️ Structure du Projet

- `lib/pages/` : Contient les différents écrans de l'application.
- `lib/compos/` : Composants UI réutilisables (Sidebar, Navbar, Cards).
- `lib/services/` : Logique de communication API et services système (Notifications, Storage).
- `lib/models/` : Modèles de données (Résultats, Sessions).

## 🛡️ Sécurité & Confidentialité
L'application respecte la vie privée des étudiants. Les autorisations sensibles (comme la caméra) ont été optimisées ou retirées pour garantir une conformité totale avec les standards du Google Play Store.

---
*Développé avec ❤️ pour la communauté estudiantine d'ESTIM.*
# appwebforshool
