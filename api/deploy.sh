#!/bin/bash
# ============================================================
# DEPLOIEMENT ESTIM CAMPUS — AlwaysData (Python WSGI)
# Usage :  ./deploy.sh            (manuel / SSH)
#          appelé auto par le webhook GitHub -> /api/deploy/webhook/
# ============================================================
set -e

# --- PARAMETRES (adapte à ton AlwaysData) ---
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANCH="main"
VENV="$APP_DIR/env"                    # venv AlwaysData (ou $HOME/virtualenv/...)
PYTHON="$VENV/bin/python"
PIP="$VENV/bin/pip"
# Fichier touché pour recharger le site WSGI (mets ton vrai .wsgi si besoin) :
RESTART_TOUCH="$APP_DIR/estim_campus_api/wsgi.py"

cd "$APP_DIR"
echo "[deploy] Dossier : $APP_DIR"

# --- 1. ENVIRONNEMENT PYTHON ---
if [ ! -x "$PYTHON" ]; then
  echo "[deploy] venv introuvable ($VENV) -> création..."
  python3 -m venv "$VENV"
fi
echo "[deploy] MAJ dépendances..."
"$PIP" install --upgrade pip -q
"$PIP" install -q -r "$APP_DIR/dep.txt"

# --- 2. CODE (git push -> pull auto) ---
# Le dépôt git est à la racine (sparse checkout : seul api/ est extrait).
GIT_DIR="$(git -C "$APP_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -n "$GIT_DIR" ]; then
  echo "[deploy] git pull ($BRANCH)..."
  # Clé SSH : sans mot de passe, le pull via HTTPS public marche déjà ;
  # si le dépôt devient privé, lance ./setup_ssh.sh --switch-remote une fois.
  if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo "[deploy] NOTE : aucune clé SSH (~/.ssh/) — lance ./setup_ssh.sh si git demande un mot de passe."
  fi
  git -C "$GIT_DIR" fetch origin
  git -C "$GIT_DIR" reset --hard "origin/$BRANCH"
else
  echo "[deploy] Pas de dépôt git ici — étape ignorée."
fi

# --- 3. VARIABLES D'ENVIRONNEMENT ---
if [ ! -f "$APP_DIR/.env" ]; then
  echo "[deploy] ATTENTION : .env absent — copie de .env.example"
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
fi

# --- 4. MIGRATIONS + STATIQUES ---
echo "[deploy] Migrations..."
"$PYTHON" manage.py migrate --noinput
echo "[deploy] Fichiers statiques..."
"$PYTHON" manage.py collectstatic --noinput

# --- 5. SUPERUSER ROOT (si inexistant) ---
echo "[deploy] Superuser root..."
"$PYTHON" manage.py ensure_root

# --- 6. RACCOURCIS DE L'APP ---
echo "[deploy] Raccourcis (apps + sites)..."
"$PYTHON" manage.py seed_shortcuts

# --- 7. RECHARGEMENT DU SITE ---
touch "$RESTART_TOUCH"
echo "[deploy] OK — site rechargé."
