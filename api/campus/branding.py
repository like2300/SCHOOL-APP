"""Callbacks dynamiques pour django-unfold : nom du site + couleurs (modifiable en admin)."""

DEFAULT_BASE = {
    "50": "oklch(98.5% .002 247.839)",
    "100": "oklch(96.7% .003 264.542)",
    "200": "oklch(92.8% .006 264.531)",
    "300": "oklch(87.2% .01 258.338)",
    "400": "oklch(70.7% .022 261.325)",
    "500": "oklch(55.1% .027 264.364)",
    "600": "oklch(44.6% .03 256.802)",
    "700": "oklch(37.3% .034 259.733)",
    "800": "oklch(27.8% .033 256.848)",
    "900": "oklch(21% .034 264.665)",
    "950": "oklch(13% .028 261.692)",
}

DEFAULT_PRIMARY = {
    "50": "oklch(97.7% .014 308.299)",
    "100": "oklch(94.6% .033 307.174)",
    "200": "oklch(90.2% .063 306.703)",
    "300": "oklch(82.7% .119 306.383)",
    "400": "oklch(71.4% .203 305.504)",
    "500": "oklch(62.7% .265 303.9)",
    "600": "oklch(55.8% .288 302.321)",
    "700": "oklch(49.6% .265 301.924)",
    "800": "oklch(43.8% .218 303.724)",
    "900": "oklch(38.1% .176 304.987)",
    "950": "oklch(29.1% .149 302.717)",
}

DEFAULT_FONT = {
    "subtle-light": "var(--color-base-500)",
    "subtle-dark": "var(--color-base-400)",
    "default-light": "var(--color-base-600)",
    "default-dark": "var(--color-base-300)",
    "important-light": "var(--color-base-900)",
    "important-dark": "var(--color-base-100)",
}


def _mix(hex_color, target, amount):
    """Mélange une couleur hex avec une cible (blanc/noir) selon amount (0..1)."""
    hex_color = hex_color.lstrip("#")
    r1, g1, b1 = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    r2, g2, b2 = int(target[0:2], 16), int(target[2:4], 16), int(target[4:6], 16)
    r = round(r1 + (r2 - r1) * amount)
    g = round(g1 + (g2 - g1) * amount)
    b = round(b1 + (b2 - b1) * amount)
    return f"#{r:02x}{g:02x}{b:02x}"


def primary_palette(hex_color):
    """Génère l'échelle 50-950 depuis une couleur hex (600 = couleur de base)."""
    return {
        "50": _mix(hex_color, "ffffff", 0.95),
        "100": _mix(hex_color, "ffffff", 0.89),
        "200": _mix(hex_color, "ffffff", 0.76),
        "300": _mix(hex_color, "ffffff", 0.58),
        "400": _mix(hex_color, "ffffff", 0.32),
        "500": _mix(hex_color, "ffffff", 0.10),
        "600": hex_color,
        "700": _mix(hex_color, "000000", 0.15),
        "800": _mix(hex_color, "000000", 0.35),
        "900": _mix(hex_color, "000000", 0.55),
        "950": _mix(hex_color, "000000", 0.72),
    }


def get_ecole_nom(request=None):
    """Nom de l'école : établissement du profil utilisateur, sinon premier établissement."""
    try:
        from .models import Etablissement, ProfilEtablissement

        if request is not None and getattr(request, "user", None) and request.user.is_authenticated:
            profil = ProfilEtablissement.objects.filter(user=request.user).first()
            if profil:
                premier = profil.etablissements.order_by("nom").first()
                if premier:
                    return premier.nom
        etab = Etablissement.objects.order_by("nom").first()
        if etab:
            return etab.nom
    except Exception:
        pass
    return None


def get_site_title(request):
    """Titre du site (onglet + en-têtes) = nom de l'école + Admin, 100 % dynamique."""
    nom = get_ecole_nom(request)
    return f"{nom} Admin" if nom else "ESTIM Admin"


def get_site_header(request):
    """Nom en haut de l'admin = nom de l'app (modifiable dans Logo / Branding)."""
    try:
        from .models import AppBranding

        branding = AppBranding.objects.filter(is_active=True).first() or AppBranding.objects.first()
        if branding and branding.app_name:
            return branding.app_name
    except Exception:
        pass
    return "ESTIM Campus"


def get_site_logo(request):
    """Logo dans la sidebar = image de l'établissement (modifiable en admin), sinon logo de l'app."""
    try:
        from .models import AppBranding, Etablissement

        url = None
        etab = Etablissement.objects.exclude(image="").exclude(image__isnull=True).first()
        if etab and etab.image:
            url = etab.image.url
        else:
            branding = AppBranding.objects.filter(is_active=True).first() or AppBranding.objects.first()
            if branding:
                url = branding.get_logo_url
        if url:
            if not url.startswith("http"):
                url = request.build_absolute_uri(url)
            if "alwaysdata.net" in url:
                url = url.replace("http://", "https://")
            return {"light": url, "dark": url}
    except Exception:
        pass
    return None


def get_admin_colors(request):
    """Palette admin = couleur du Thème actif (modifiable dans Configuration)."""
    try:
        from .models import ThemeConfig

        theme = ThemeConfig.objects.filter(is_active=True).first()
        if theme and theme.primary_color and len(theme.primary_color) == 7:
            return {
                "base": dict(DEFAULT_BASE),
                "primary": primary_palette(theme.primary_color),
                "font": dict(DEFAULT_FONT),
            }
    except Exception:
        pass
    return {
        "base": dict(DEFAULT_BASE),
        "primary": dict(DEFAULT_PRIMARY),
        "font": dict(DEFAULT_FONT),
    }


def badge_inscriptions_attente(request):
    """Pastille sidebar : dossiers d'inscription en attente."""
    try:
        from inscription.models import Inscription

        return Inscription.objects.filter(statut="EN_ATTENTE").count() or ""
    except Exception:
        return ""


def badge_dettes(request):
    """Pastille sidebar : paiements dont le SMS n'est pas parti."""
    try:
        from .models import PaiementScolarite

        return PaiementScolarite.objects.filter(sms_envoye=False).count() or ""
    except Exception:
        return ""
