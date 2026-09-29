"""Webhook de redéploiement auto : GitHub (push) -> AlwaysData.

POST /api/deploy/webhook/
Sécurité : header `X-Deploy-Token: <DEPLOY_WEBHOOK_SECRET>`
ou signature GitHub `X-Hub-Signature-256` (HMAC du body avec le même secret).
Sans secret configuré -> 403 avec consigne.
Le déploiement (deploy.sh) tourne en tâche de fond, log dans deploy.log.
"""

import hashlib
import hmac
import os
import subprocess
import threading
from datetime import datetime

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG_FILE = os.path.join(BASE_DIR, "deploy.log")
DEPLOY_SH = os.path.join(BASE_DIR, "deploy.sh")


def _log(msg):
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}\n"
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def _run_deploy():
    _log("=== Déploiement démarré (webhook) ===")
    try:
        proc = subprocess.run(
            ["bash", DEPLOY_SH],
            cwd=BASE_DIR,
            capture_output=True,
            text=True,
            timeout=600,
        )
        _log(proc.stdout[-4000:])
        if proc.stderr:
            _log("STDERR: " + proc.stderr[-2000:])
        _log(f"=== Déploiement terminé (code {proc.returncode}) ===")
    except Exception as e:  # noqa: BLE001 - log only
        _log(f"ERREUR déploiement : {e}")


@csrf_exempt
def deploy_webhook(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST uniquement"}, status=405)

    secret = os.getenv("DEPLOY_WEBHOOK_SECRET", "").strip()
    if not secret:
        return JsonResponse(
            {"error": "Webhook non configuré : définis DEPLOY_WEBHOOK_SECRET dans .env"},
            status=403,
        )

    body = request.body or b""
    # 1) Signature GitHub (si présente, elle fait foi).
    sig = request.headers.get("X-Hub-Signature-256", "")
    authorized = False
    if sig.startswith("sha256="):
        expected = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        authorized = hmac.compare_digest(expected, sig)
    # 2) Sinon token partagé (header ou ?token=).
    if not authorized:
        token = request.headers.get("X-Deploy-Token", "") or request.GET.get("token", "")
        authorized = hmac.compare_digest(token, secret)

    if not authorized:
        _log("Webhook refusé : token/signature invalide.")
        return JsonResponse({"error": "Non autorisé"}, status=403)

    if not os.path.exists(DEPLOY_SH):
        return JsonResponse({"error": "deploy.sh introuvable"}, status=500)

    threading.Thread(target=_run_deploy, daemon=True).start()
    _log("Webhook push reçu — déploiement lancé en arrière-plan.")
    return JsonResponse({"ok": True, "message": "Déploiement lancé"})
