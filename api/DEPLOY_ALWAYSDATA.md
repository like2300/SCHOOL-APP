# Déploiement AlwaysData — ESTIM Campus (via GitHub Actions SSH)

## Option A : site Python WSGI (rechargement auto)

| Champ | Valeur |
|---|---|
| **Type** | Python WSGI |
| **Application path** | `/home/school-open/estim_campus/api/estim.wsgi` |
| **Working directory** | `/home/school-open/estim_campus/api` |
| **Environment variables** | vide (tout est dans `api/.env`) |
| **Python version** | 3.13 |
| **virtualenv directory** | `/home/school-open/estim_campus/api/env` |
| **Static paths** | `/static/=/home/school-open/estim_campus/api/staticfiles` et `/media/=/home/school-open/estim_campus/api/media` |

Le `touch estim.wsgi` de `deploy.sh` recharge le site tout seul.

## Option B : site User program (gunicorn — oui, c'est possible)

| Champ | Valeur |
|---|---|
| **Type** | User program |
| **Command** | `/home/school-open/estim_campus/api/start.sh` |
| **Working directory** | `/home/school-open/estim_campus/api` |
| **Environment variables** | vide (tout est dans `api/.env`) |
| **Static paths** | idem option A |

`start.sh` lance `gunicorn` sur le `$PORT` fourni par AlwaysData (2 workers,
logs vers la sortie). Après chaque `./deploy.sh`, fais **Restart** du programme
dans le panel (Sites > ton site > Restart) — le user program ne recharge pas
tout seul au `touch`.

## 0. Cloner QUE l'API (pas tout le dépôt)

Sur le serveur, on ne récupère que le dossier `api/` :

```bash
git clone --no-checkout https://github.com/like2300/SCHOOL-APP.git estim_campus
cd estim_campus
git sparse-checkout init --cone
git sparse-checkout set api
git checkout main
ls api   # -> manage.py, deploy.sh, campus/, inscription/...
```

Toutes les commandes ci-dessous se font ensuite dans `estim_campus/api`.
Le webhook et `deploy.sh` (`git reset --hard origin/$BRANCH`) respectent
le sparse checkout : seule l'API est mise à jour à chaque `git push`.

## 1. Préparation (une fois, en SSH)

```bash
cd ~/estim_campus/api        # dossier du projet sur AlwaysData
python3 -m venv env
./env/bin/pip install -r dep.txt
cp .env.example .env         # puis édite .env (SECRET, DB, DEPLOY_WEBHOOK_SECRET...)
chmod +x deploy.sh setup_ssh.sh
./deploy.sh                  # 1er déploiement complet
```

## 1b. Clé SSH (pull sans mot de passe)

```bash
cd ~/estim_campus/api
./setup_ssh.sh               # génère ~/.ssh/id_ed25519 + affiche la clé publique
```

Copie la clé affichée vers GitHub > **like2300/SCHOOL-APP > Settings > Deploy keys >
Add deploy key** (lecture seule suffit), puis :

```bash
./setup_ssh.sh --switch-remote   # origin passe en git@github.com:... (SSH)
```

`deploy.sh` te préviendra tout seul si aucune clé SSH n'existe.

`deploy.sh` fait : `git pull` → dépendances → `migrate` → `collectstatic` →
`ensure_root` (crée **root / root** si inexistant) → `seed_shortcuts`
(apps + sites de l'app) → `touch wsgi.py` (rechargement).

## 2. Rechargement auto à chaque `git push`

1. Dans `.env`, définis un secret long : `DEPLOY_WEBHOOK_SECRET=...`
2. Redémarre le site une fois (pour charger le `.env`).
3. GitHub > **Settings > Webhooks > Add webhook** :
   - URL : `https://estim-campus.alwaysdata.net/api/deploy/webhook/`
   - Content type : `application/json`
   - Secret : la même valeur que `DEPLOY_WEBHOOK_SECRET`
   - Events : **Just the push event**
4. À chaque push sur `main` : pull + migrate + collectstatic + restart, log dans `api/deploy.log`.

Test manuel : `curl -X POST https://.../api/deploy/webhook/ -H "X-Deploy-Token: TON_SECRET"`.

## 3. Comptes & variables

| Variable | Rôle | Défaut |
|---|---|---|
| `DJANGO_SUPERUSER_USERNAME/PASSWORD` | superuser créé par `ensure_root` | root / root |
| `DATABASE_URL` | `sqlite:///db.sqlite3` ou postgres AlwaysData | sqlite |
| `DEPLOY_WEBHOOK_SECRET` | sécurise le webhook (obligatoire, sinon 403) | vide = webhook désactivé |

## 4. Commandes utiles

```bash
./env/bin/python manage.py ensure_root      # crée root si absent
./env/bin/python manage.py seed_shortcuts   # ajoute les raccourcis manquants
./env/bin/python manage.py migrate
tail -f deploy.log                          # suivre un déploiement webhook
```
