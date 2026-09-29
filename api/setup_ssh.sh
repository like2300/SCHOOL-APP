#!/bin/bash
# ============================================================
# CLE SSH POUR DEPLOIEMENT AUTO (AlwaysData -> GitHub)
# Usage : ./setup_ssh.sh [--switch-remote]
#   - génère ~/.ssh/id_ed25519 (sans passphrase) si absente
#   - affiche la clé publique à ajouter sur GitHub
#   - --switch-remote : bascule `origin` en SSH (plus de mot de passe au pull)
# ============================================================
set -e

KEY="$HOME/.ssh/id_ed25519"
PUB="$KEY.pub"
REPO_SSH="git@github.com:like2300/SCHOOL-APP.git"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$KEY" ]; then
  echo "[ssh] Génération de la clé SSH..."
  ssh-keygen -t ed25519 -N "" -C "alwaysdata-deploy" -f "$KEY" -q
  chmod 600 "$KEY"
else
  echo "[ssh] Clé existante : $KEY"
fi

echo ""
echo "================ CLÉ PUBLIQUE (à copier) ================"
cat "$PUB"
echo "========================================================="
echo ""
echo "1. GitHub > like2300/SCHOOL-APP > Settings > Deploy keys > Add deploy key"
echo "   (colle la clé ci-dessus, Allow write access : NON coché — pull uniquement)."
echo "2. Puis relance avec : ./setup_ssh.sh --switch-remote"
echo ""

if [ "$1" = "--switch-remote" ]; then
  GIT_TOP="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [ -z "$GIT_TOP" ]; then
    echo "[ssh] Pas de dépôt git trouvé ici."; exit 1
  fi
  # Test de connexion (n'échoue pas le script si refusé).
  if ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[ssh] Connexion GitHub OK."
  else
    echo "[ssh] AVERTISSEMENT : test SSH GitHub non concluant (clé pas encore ajoutée ?)."
  fi
  git -C "$GIT_TOP" remote set-url origin "$REPO_SSH"
  git -C "$GIT_TOP" fetch origin
  echo "[ssh] Remote origin basculé en SSH : $REPO_SSH"
fi
