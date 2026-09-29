#!/bin/bash
# ============================================================
# LANCEMENT API — AlwaysData (site type "User program").
# Dans le panel : Command = /home/school-open/estim_campus/api/start.sh
#  - libère $PORT s'il est squatté par un vieux processus
#  - relance gunicorn tout seul en cas de crash (backoff)
# ============================================================
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"
PORT="${PORT:-8100}"
WORKERS="${GUNICORN_WORKERS:-2}"
GUNICORN="$APP_DIR/env/bin/gunicorn"

port_occupe() {
  # vrai (0) si quelque chose répond sur le port = occupé.
  (exec 3<>/dev/tcp/127.0.0.1/"$1") 2>/dev/null && return 0 || return 1
}

libere_port() {
  local port="$1" essais=0
  while port_occupe "$port" && [ "$essais" -lt 3 ]; do
    echo "[start] Port $port occupé — libération (essai $((essais + 1))/3)..."
    if command -v fuser >/dev/null 2>&1; then
      fuser -k "$port/tcp" >/dev/null 2>&1 || true
    else
      # Repli : tue nos vieux gunicorn du même venv.
      pkill -f "$APP_DIR/env/bin/gunicorn" 2>/dev/null || true
    fi
    essais=$((essais + 1))
    sleep 2
  done
  if port_occupe "$port"; then
    echo "[start] ERREUR : port $port toujours occupé, abandon."
    return 1
  fi
  echo "[start] Port $port libre."
  return 0
}

if [ ! -x "$GUNICORN" ]; then
  echo "[start] ERREUR : gunicorn introuvable ($GUNICORN). Lance ./deploy.sh d'abord."
  exit 1
fi

# Important : on garde le $PORT d'AlwaysData (le proxy route vers lui).
libere_port "$PORT" || exit 1

delai=2
while true; do
  echo "[start] Lancement gunicorn sur 127.0.0.1:$PORT (workers=$WORKERS)..."
  "$GUNICORN" estim_campus_api.wsgi:application \
    --bind "127.0.0.1:$PORT" \
    --workers "$WORKERS" \
    --timeout 60 \
    --access-logfile - \
    --error-logfile -
  code=$?
  echo "[start] gunicorn arrêté (code $code) — redémarrage dans ${delai}s..."
  sleep "$delai"
  delai=$((delai < 30 ? delai * 2 : 30))
  libere_port "$PORT" || exit 1
done
