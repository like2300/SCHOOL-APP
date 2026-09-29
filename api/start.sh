#!/bin/bash
# ============================================================
# LANCEMENT API — AlwaysData (site type "User program").
# Dans le panel : Command = /home/school-open/estim_campus/api/start.sh
# AlwaysData fournit $PORT : gunicorn écoute dessus.
# ============================================================
set -e
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"
PORT="${PORT:-8000}"
WORKERS="${GUNICORN_WORKERS:-2}"
exec "$APP_DIR/env/bin/gunicorn" estim_campus_api.wsgi:application \
  --bind "127.0.0.1:$PORT" \
  --workers "$WORKERS" \
  --timeout 60 \
  --access-logfile - \
  --error-logfile -
