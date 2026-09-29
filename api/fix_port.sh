#!/bin/bash
# ============================================================
# FIX_PORT — répare un port squatté (ex : ./fix_port.sh 8100).
#  1. tue le vieux master via .gunicorn.pid (nos orphelins)
#  2. fuser -k + pkill (gunicorn / runserver du compte)
#  3. vérifie par un vrai bind python
#  Si le holder est invisible (autre cgroup) : affiche la marche
#  à suivre (Stop/wait/Start panel, ticket support).
# ============================================================
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${1:-${PORT:-8100}}"
PIDFILE="$APP_DIR/.gunicorn.pid"

echo "[fix] Port visé : $PORT"

# --- 1. pidfile de nos anciens masters ---
if [ -f "$PIDFILE" ]; then
  pid=$(tr -dc '0-9' < "$PIDFILE" | head -c 10)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "[fix] Ancien master gunicorn PID $pid — arrêt..."
    kill "$pid" 2>/dev/null || true
    sleep 3
    kill -9 "$pid" 2>/dev/null || true
  else
    echo "[fix] Pas de master actif via pidfile."
  fi
  rm -f "$PIDFILE"
fi

# --- 2. fuser + pkill (3 passages) ---
for i in 1 2 3; do
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "$PORT/tcp" >/dev/null 2>&1 || true
  fi
  pkill -f "$APP_DIR/env/bin/gunicorn" 2>/dev/null || true
  pkill -f "manage.py runserver" 2>/dev/null || true
  sleep 2
done

# --- 3. vérification par bind réel ---
if python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',$PORT)); s.close(); print('BIND OK')" 2>/dev/null; then
  echo "[fix] SUCCÈS : 127.0.0.1:$PORT libre — fais Restart dans le panel."
  exit 0
fi

echo "[fix] ÉCHEC : le port reste tenu par un processus invisible."
echo "[fix] Qui le tient ?"
ss -ltnpe 2>/dev/null | grep ":$PORT " || ss -ltnp 2>/dev/null | grep ":$PORT "
echo ""
echo "[fix] Marche à suivre :"
echo "  1. Panel AlwaysData > programme > Stop, attends 60 s, vérifie"
echo "     que 'ss -ltnp | grep $PORT' ne retourne plus rien, puis Start."
echo "  2. Si la ligne persiste sans processus visible : ticket support"
echo "     AlwaysData avec la ligne 'ss' ci-dessus (holder hors de ton cgroup)."
echo "  3. Alternative sans port : repasse le site en Python WSGI (estim.wsgi)."
exit 1
