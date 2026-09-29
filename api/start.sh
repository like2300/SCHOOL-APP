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
# Override optionnel : APP_PORT=8200 pour binder un autre port que $PORT.
BIND_PORT="${APP_PORT:-$PORT}"
WORKERS="${GUNICORN_WORKERS:-2}"
GUNICORN="$APP_DIR/env/bin/gunicorn"

# Verrou : une seule instance à la fois (le superviseur relance parfois
# start.sh en double -> les deux lieraient le même port en même temps).
LOCK="$APP_DIR/.start.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK"
  if ! flock -n 9; then
    echo "[start] Une autre instance tourne déjà — arrêt propre."
    exit 0
  fi
fi

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
      tue_squatteur "$port"
    fi
    essais=$((essais + 1))
    sleep 2
  done
  if port_occupe "$port"; then
    echo "[start] ERREUR : port $port toujours occupé, abandon."
    echo "[start] Diagnostic : lance 'ss -ltnp | grep $port' + 'ps aux | grep -E \"gunicorn|runserver\"' en SSH."
    return 1
  fi
  echo "[start] Port $port libre."
  return 0
}

tue_squatteur() {
  # Trouve le PID qui écoute sur le port (ss ou lsof) et le tue
  # seulement si c'est un python/gunicorn (jamais un processus système).
  local port="$1" pids="" pid="" cmd=""
  if command -v ss >/dev/null 2>&1; then
    pids=$(ss -ltnp 2>/dev/null | grep ":$port " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | sort -u)
  elif command -v lsof >/dev/null 2>&1; then
    pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null)
  else
    pkill -f "$APP_DIR/env/bin/gunicorn" 2>/dev/null || true
    return 0
  fi
  if [ -z "$pids" ]; then
    echo "[start] Aucun PID visible pour le port $port (permissions ?) — repli pkill."
    pkill -f "$APP_DIR/env/bin/gunicorn" 2>/dev/null || true
    pkill -f "manage.py runserver" 2>/dev/null || true
    return 0
  fi
  for pid in $pids; do
    if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
      cmd=$(ps -o comm= -p "$pid" 2>/dev/null || echo "?")
      case "$cmd" in
        python*|gunicorn*)
          echo "[start] kill PID $pid ($cmd)..."
          kill "$pid" 2>/dev/null || true
          sleep 1
          kill -9 "$pid" 2>/dev/null || true
          ;;
        *) echo "[start] PID $pid ($cmd) non python — pas touché." ;;
      esac
    fi
  done
}

if [ ! -x "$GUNICORN" ]; then
  echo "[start] ERREUR : gunicorn introuvable ($GUNICORN). Lance ./deploy.sh d'abord."
  exit 1
fi

# Important : AlwaysData route vers $PORT. Si APP_PORT est différent,
# le site ne répondra plus via le proxy (log d'avertissement ci-dessous).
if [ "$BIND_PORT" != "$PORT" ]; then
  echo "[start] ATTENTION : bind sur $BIND_PORT alors que le proxy vise $PORT — le site risque d'être injoignable."
fi
libere_port "$BIND_PORT" || exit 1

delai=2
while true; do
  echo "[start] Lancement gunicorn sur 127.0.0.1:$BIND_PORT (workers=$WORKERS)..."
  "$GUNICORN" estim_campus_api.wsgi:application \
    --bind "127.0.0.1:$BIND_PORT" \
    --workers "$WORKERS" \
    --timeout 60 \
    --access-logfile - \
    --error-logfile -
  code=$?
  echo "[start] gunicorn arrêté (code $code) — redémarrage dans ${delai}s..."
  sleep "$delai"
  delai=$((delai < 30 ? delai * 2 : 30))
  libere_port "$BIND_PORT" || exit 1
done
