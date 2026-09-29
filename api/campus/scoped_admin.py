"""Scoping admin par établissement(s).

Un superuser voit tout. Un staff avec ProfilEtablissement ne voit
que les lignes de SES établissements (un ou plusieurs).
"""
from django import forms


def get_user_etablissements(user):
    """Liste des établissements gérés. None = accès total (superuser / sans profil)."""
    if not user or not user.is_authenticated:
        return None
    if user.is_superuser:
        return None  # None = accès total
    try:
        etabs = list(user.profil_etablissement.etablissements.all())
        return etabs or None
    except Exception:
        return None


def get_user_etablissement(user):
    """Compat : premier établissement géré (ou None = accès total)."""
    etabs = get_user_etablissements(user)
    if etabs is None:
        return None
    return etabs[0] if etabs else None


def is_scoped_user(user):
    if not user or not user.is_authenticated or user.is_superuser:
        return False
    return get_user_etablissements(user) is not None


class EtablissementScopedAdminMixin:
    """À mixer dans les ModelAdmin ayant un FK `etablissement`.

    - get_queryset : filtre sur les établissements du user.
    - save_model : force l'établissement du user à la création (si un seul).
    - get_form/formfield : limite le dropdown aux écoles gérées + présélectionne.
    """

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        etabs = get_user_etablissements(request.user)
        if etabs is not None and hasattr(self.model, "etablissement"):
            qs = qs.filter(etablissement__in=etabs)
        return qs

    def save_model(self, request, obj, form, change):
        etabs = get_user_etablissements(request.user)
        if etabs is not None and hasattr(obj, "etablissement_id") and not obj.etablissement_id:
            obj.etablissement = etabs[0]
        super().save_model(request, obj, form, change)

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        etabs = get_user_etablissements(request.user)
        if etabs is not None and db_field.name == "etablissement":
            kwargs["queryset"] = type(etabs[0]).objects.filter(pk__in=[e.pk for e in etabs])
            kwargs["initial"] = etabs[0].pk
            if len(etabs) == 1:
                kwargs["disabled"] = True
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def has_delete_permission(self, request, obj=None):
        etabs = get_user_etablissements(request.user)
        if etabs is not None and obj is not None and hasattr(obj, "etablissement_id"):
            return obj.etablissement_id in [e.pk for e in etabs]
        return super().has_delete_permission(request, obj)
