"""Point d'entrée WSGI pour AlwaysData (site Python WSGI).

Dans le panel : Application path = /home/school-open/estim_campus/api/estim.wsgi
Le venv est ajouté au sys.path, le .env est chargé depuis le dossier api/
(Working directory = /home/school-open/estim_campus/api).
"""
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VENV_SITE = os.path.join(BASE_DIR, "env", "lib")
if os.path.isdir(VENV_SITE):
    # Ajoute les site-packages du venv (peu importe la version mineure de Python).
    import glob as _glob

    for _p in _glob.glob(os.path.join(VENV_SITE, "python3*", "site-packages")):
        if os.path.isdir(_p) and _p not in sys.path:
            sys.path.insert(0, _p)
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "estim_campus_api.settings")

# Charge api/.env (le Working directory AlwaysData doit être BASE_DIR).
try:
    from dotenv import load_dotenv

    load_dotenv(os.path.join(BASE_DIR, ".env"))
except ImportError:
    pass

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()
