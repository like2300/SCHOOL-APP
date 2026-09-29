"""Message auto envoyé dès qu'un résultat est disponible.

Contenu : session + moyenne/admis, lien de téléchargement de l'app
(récupéré dans la DB : FormConfig.app_download_url) et infos de
connexion du compte (ID étudiant + n° téléphone de la fiche).
"""


def find_inscription_for_resultat(resultat):
    """Retrouve la fiche d'inscription liée (VALIDÉE d'abord) par le nom."""
    from inscription.models import Inscription

    parts = (resultat.nom_etudiant or "").split()
    if not parts:
        return None
    qs = Inscription.objects.all()
    if len(parts) >= 2:
        hit = qs.filter(
            last_name__icontains=parts[0], first_name__icontains=parts[-1],
            statut="VALIDEE",
        ).first() or qs.filter(
            last_name__icontains=parts[0], first_name__icontains=parts[-1],
        ).first()
    else:
        hit = qs.filter(last_name__icontains=parts[0], statut="VALIDEE").first() or \
            qs.filter(last_name__icontains=parts[0]).first()
    return hit


def build_resultat_message(resultat, inscription):
    """Texte du message : résultat + lien app (DB) + identifiants."""
    from inscription.models import FormConfig

    try:
        ecole = (inscription.target_etablissement or "").strip() or "ESTIM"
    except Exception:
        ecole = "ESTIM"
    session_nom = ""
    try:
        session_nom = resultat.session.nom if resultat.session_id else ""
    except Exception:
        pass
    verdict = "ADMIS(E)" if resultat.admis else "AJOURNÉ(E)"
    try:
        moyenne = f"{float(resultat.moyenne):.2f}"
    except (TypeError, ValueError):
        moyenne = str(resultat.moyenne)

    config = FormConfig.objects.filter(is_active=True).first()
    app_link = (config.app_download_url if config and config.app_download_url else "").strip()

    lignes = [
        f"{ecole} : resultat disponible !",
        f"Eleve : {resultat.nom_etudiant} ({resultat.matricule})",
        f"Session : {session_nom} — Moyenne : {moyenne} — {verdict}",
        "",
        "Consulte ton resultat dans l'app :",
        f"ID etudiant : {inscription.student_id or f'INS-{inscription.pk}'}",
        f"Telephone : {inscription.phone or inscription.tel_tuteur or ''}".strip(),
    ]
    if app_link:
        lignes += ["", f"Telecharge l'app ici : {app_link}"]
    lignes.append(f"{ecole} vous remercie.")
    return "\n".join(lignes)
