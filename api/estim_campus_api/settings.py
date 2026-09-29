import os
from pathlib import Path

import dj_database_url
from django.urls import reverse_lazy
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

# Configuration CSRF pour la production
CSRF_TRUSTED_ORIGINS = [
    "https://estim-campus.alwaysdata.net",
    "https://estim-web.netlify.app",
]


# Autoriser les en-têtes spécifiques
CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

# Autoriser les méthodes HTTP spécifiques
CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "django-insecure-default-key-change-me")

OPENPAY_API_KEY = os.getenv("OPENPAY_API_KEY", "")

# WhatsApp / SMS tuteur (paiements scolarité) — clé via .env de préférence
WHATSAPP_API_URL = os.getenv(
    "WHATSAPP_API_URL", "https://omerlinkchat.alwaysdata.net/api/send"
)
WHATSAPP_API_TOKEN = os.getenv(
    "WHATSAPP_API_TOKEN",
    "otp_5bac7b03217a742687a0e41eb060a64fc8d6d988ffba27ca58fd6cb48b4300b3",
)
WHATSAPP_ENABLED = os.getenv("WHATSAPP_ENABLED", "True") == "True"
# Délai minimum entre 2 envois (anti-blocage WhatsApp) + quota journalier
WHATSAPP_MIN_DELAY_SECONDS = int(os.getenv("WHATSAPP_MIN_DELAY_SECONDS", "12"))
WHATSAPP_DAILY_LIMIT = int(os.getenv("WHATSAPP_DAILY_LIMIT", "500"))
WHATSAPP_TIMEOUT = int(os.getenv("WHATSAPP_TIMEOUT", "10"))

# URL publique de l'école (liens WhatsApp : fiche d'inscription...)
SITE_BASE_URL = os.getenv("SITE_BASE_URL", "https://estim-campus.alwaysdata.net").rstrip("/")

# DEBUG est géré par .env (False en production, True en dev)
DEBUG = os.getenv("DJANGO_DEBUG", "True") == "True"

# Hôtes autorisés - Production uniquement
allowed_hosts_env = os.getenv("DJANGO_ALLOWED_HOSTS", "")
ALLOWED_HOSTS = (
    allowed_hosts_env.split(",")
    if allowed_hosts_env
    else ["estim-campus.alwaysdata.net"]
)
# Toujours autoriser le dev local (runserver) même avec le .env de prod
for _local_host in ("localhost", "127.0.0.1", "[::1]", "testserver", "10.0.2.2"):
    if _local_host not in ALLOWED_HOSTS:
        ALLOWED_HOSTS.append(_local_host)

# Sécurité HTTPS en production
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = os.getenv("DJANGO_SECURE_SSL_REDIRECT", "True") == "True"
    SESSION_COOKIE_SECURE = os.getenv("DJANGO_SESSION_COOKIE_SECURE", "True") == "True"
    CSRF_COOKIE_SECURE = os.getenv("DJANGO_CSRF_COOKIE_SECURE", "True") == "True"
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_HSTS_SECONDS = 31536000  # 1 an
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True

INSTALLED_APPS = [
    "unfold",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "campus",
    "inscription",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # Pour les fichiers statiques
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

CORS_ALLOW_ALL_ORIGINS = (
    False  # Désactivé pour la sécurité, utilise CORS_ALLOWED_ORIGINS
)
if DEBUG:
    # Dev local : le port du `flutter run -d chrome` est aléatoire,
    # on ouvre CORS en dev uniquement (jamais en production).
    CORS_ALLOW_ALL_ORIGINS = True

# CORS allowed origins from .env
cors_origins = os.getenv("CSRF_TRUSTED_ORIGINS", "")
if cors_origins:
    CORS_ALLOWED_ORIGINS = cors_origins.split(",")

ROOT_URLCONF = "estim_campus_api.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "estim_campus_api.wsgi.application"

# Database - Utilise DATABASE_URL en prod, sqlite en local
DATABASES = {
    "default": dj_database_url.config(
        default=f"sqlite:///{BASE_DIR}/db.sqlite3", conn_max_age=600
    )
}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
    },
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "fr-fr"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [
    BASE_DIR / "static",
]

# Utiliser le stockage standard en local pour éviter les erreurs de manifeste
if DEBUG:
    STATICFILES_STORAGE = "django.contrib.staticfiles.storage.StaticFilesStorage"
else:
    STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Redirection vers la page de connexion de l'admin par défaut
LOGIN_URL = "/admin/login/"
LOGIN_REDIRECT_URL = "/api/dashboard/"
LOGOUT_REDIRECT_URL = "/admin/login/"

# Branding + sidebar de l'admin (django-unfold)
UNFOLD = {
    "DASHBOARD_CALLBACK": "campus.dashboard.dashboard_callback",
    "SITE_TITLE": "campus.branding.get_site_title",
    "SITE_HEADER": "campus.branding.get_site_header",
    "SITE_SYMBOL": "school",
    "SITE_LOGO": "campus.branding.get_site_logo",
    "COLORS": "campus.branding.get_admin_colors",
    "SHOW_HISTORY": True,
    "SHOW_VIEW_ON_SITE": False,
    "SHOW_BACK_BUTTON": True,
    "BORDER_RADIUS": "8px",
    "LOGIN": {
        "redirect_after": lambda request: reverse_lazy("admin:index"),
    },
    "TABS": [
        {
            "models": ["inscription.inscription"],
            "items": [
                {"title": "Toutes", "link": reverse_lazy("admin:inscription_inscription_changelist")},
                {"title": "En attente", "link": "/admin/inscription/inscription/?statut__exact=EN_ATTENTE"},
                {"title": "Validées", "link": "/admin/inscription/inscription/?statut__exact=VALIDEE"},
                {"title": "Rejetées", "link": "/admin/inscription/inscription/?statut__exact=REJETEE"},
            ],
        },
        {
            "models": ["campus.cours"],
            "items": [
                {"title": "Liste", "link": reverse_lazy("admin:campus_cours_changelist")},
                {"title": "Calendrier", "link": "/admin/campus/cours/calendrier/"},
            ],
        },
        {
            "models": ["campus.paiementscolarite"],
            "items": [
                {"title": "Paiements", "link": reverse_lazy("admin:campus_paiementscolarite_changelist")},
                {"title": "Suivi des dettes", "link": "/admin/campus/paiementscolarite/suivi/"},
            ],
        },
        {
            "models": ["campus.siteweb"],
            "items": [
                {"title": "Liste", "link": reverse_lazy("admin:campus_siteweb_changelist")},
                {"title": "Aperçu", "link": "/admin/campus/siteweb/apercu/"},
            ],
        },
    ],
    "SIDEBAR": {
        "show_search": True,
        "navigation": [
            {
                "title": "Pédagogie",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Cours", "icon": "book", "link": "/admin/campus/cours/"},
                    {"title": "Examens", "icon": "quiz", "link": "/admin/campus/examen/"},
                    {"title": "Résultats", "icon": "grade", "link": "/admin/campus/resultat/"},
                    {"title": "Sessions d'examen", "icon": "event", "link": "/admin/campus/sessionexamen/"},
                    {"title": "Calendrier académique", "icon": "calendar_month", "link": "/admin/campus/calendrieracademique/"},
                ],
            },
            {
                "title": "Vie du campus",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Annonces", "icon": "newspaper", "link": "/admin/campus/annonce/"},
                    {"title": "Notifications", "icon": "notifications", "link": "/admin/campus/notification/"},
                    {"title": "Images d'accueil", "icon": "image", "link": "/admin/campus/heroimage/"},
                    {"title": "Applications campus", "icon": "apps", "link": "/admin/campus/campusapp/"},
                    {"title": "Sites web", "icon": "public", "link": "/admin/campus/siteweb/"},
                ],
            },
            {
                "title": "Référentiels",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Établissements", "icon": "business", "link": "/admin/campus/etablissement/"},
                    {"title": "Niveaux", "icon": "layers", "link": "/admin/campus/niveau/"},
                    {"title": "Filières", "icon": "category", "link": "/admin/campus/filiere/"},
                    {"title": "Tarifs scolarité", "icon": "sell", "link": "/admin/campus/tarifscolarite/"},
                    {"title": "Années académiques", "icon": "date_range", "link": "/admin/campus/anneeacademique/"},
                ],
            },
            {
                "title": "Inscriptions",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Inscriptions", "icon": "how_to_reg", "link": "/admin/inscription/inscription/",
                     "badge": "campus.branding.badge_inscriptions_attente", "badge_variant": "warning"},
                ],
            },
            {
                "title": "Personnel",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Employés", "icon": "badge", "link": "/admin/campus/employe/"},
                    {"title": "Bulletins de paie", "icon": "request_quote", "link": "/admin/campus/bulletinpaie/"},
                ],
            },
            {
                "title": "Paiements",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Transactions", "icon": "payments", "link": "/admin/campus/transaction/"},
                    {"title": "Paiements réussis", "icon": "paid", "link": "/admin/campus/paiement/"},
                    {"title": "Paiements scolarité", "icon": "receipt_long", "link": "/admin/campus/paiementscolarite/"},
                    {"title": "Suivi des dettes", "icon": "monitoring", "link": "/admin/campus/paiementscolarite/suivi/",
                     "badge": "campus.branding.badge_dettes", "badge_variant": "danger"},
                    {"title": "Journal WhatsApp", "icon": "mark_chat_read", "link": "/admin/campus/messagelog/"},
                ],
            },
            {
                "title": "Configuration",
                "separator": True,
                "collapsible": True,
                "items": [
                    {"title": "Thème de l'admin", "icon": "palette", "link": "/admin/campus/themeconfig/"},
                    {"title": "Logo / Branding", "icon": "smartphone", "link": "/admin/campus/appbranding/"},
                    {"title": "Slides d'onboarding", "icon": "view_carousel", "link": "/admin/campus/onboardingslide/"},
                    {"title": "Assistant IA", "icon": "smart_toy", "link": "/admin/campus/assistantia/"},
                    {"title": "Configs fiches", "icon": "settings", "link": "/admin/inscription/formconfig/"},
                ],
            },
            {
                "title": "Comptes & accès",
                "separator": True,
                "items": [
                    {"title": "Créer un compte", "icon": "person_add", "link": "/admin/campus/profiletablissement/creer/"},
                    {"title": "Admins d'établissement", "icon": "manage_accounts", "link": "/admin/campus/profiletablissement/"},
                    {"title": "Utilisateurs", "icon": "group", "link": "/admin/auth/user/"},
                ],
            },
        ],
    },
}
