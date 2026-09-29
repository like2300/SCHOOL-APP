import openpyxl
from django import forms
from django.http import HttpResponse
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Inscription, FormConfig

CIVIL_CHOICES = [
    ("CELIBATAIRE", "Célibataire"),
    ("MARIE", "Marié(e)"),
    ("DIVORCE", "Divorcé(e)"),
    ("VEUF", "Veuf / Veuve"),
]

OCCUPATION_CHOICES = [
    ("ELEVE", "Élève"),
    ("ETUDIANT", "Étudiant(e)"),
    ("FONCTIONNAIRE", "Fonctionnaire"),
    ("SALARIE_PRIVE", "Salarié du privé"),
    ("COMMERCANT", "Commerçant(e)"),
    ("ENTREPRENEUR", "Entrepreneur(e)"),
    ("SANS_EMPLOI", "Sans emploi"),
    ("AUTRE", "Autre"),
]

BAC_SERIE_CHOICES = [
    ("A", "Bac A"),
    ("C", "Bac C"),
    ("D", "Bac D"),
    ("E", "Bac E"),
    ("F", "Bac F"),
    ("G", "Bac G"),
    ("H", "Bac H"),
    ("TI", "Bac TI"),
    ("PRO", "Bac Pro"),
    ("EQUIVALENCE", "Équivalence / Diplôme étranger"),
    ("AUTRE", "Autre"),
]

INFO_LEVEL_CHOICES = [
    ("DEBUTANT", "Débutant"),
    ("INTERMEDIAIRE", "Intermédiaire"),
    ("AVANCE", "Avancé"),
    ("EXPERT", "Expert"),
]


class InscriptionAdminForm(forms.ModelForm):
    """Formulaire admin : selects alimentés par les référentiels (pratique au bureau)."""

    class Meta:
        model = Inscription
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        from campus.models import AnneeAcademique, Etablissement, Filiere, Niveau

        etabs = list(Etablissement.objects.order_by("nom"))
        if etabs:
            self.fields["target_etablissement"] = forms.ChoiceField(
                choices=[(e.nom.upper(), e.nom) for e in etabs],
                label="ESTIM d'inscription",
            )
            if self.instance and self.instance.pk and self.instance.target_etablissement:
                self.initial.setdefault("target_etablissement", self.instance.target_etablissement)

        annees = list(AnneeAcademique.objects.order_by("-nom"))
        if annees:
            self.fields["annee_academique"] = forms.ChoiceField(
                choices=[("", "—")] + [(a.nom, a.nom) for a in annees],
                required=False, label="Année Académique",
            )

        self.fields["civil"] = forms.ChoiceField(choices=CIVIL_CHOICES, label="Statut matrimonial")
        self.fields["occupation"] = forms.ChoiceField(choices=OCCUPATION_CHOICES, label="Occupation actuelle")
        self.fields["bac_serie"] = forms.ChoiceField(choices=BAC_SERIE_CHOICES, label="Baccalauréat série")

        niveaux = list(Niveau.objects.order_by("nom"))
        if niveaux:
            self.fields["choix_cycle"] = forms.ChoiceField(
                choices=[(n.nom.upper(), n.nom) for n in niveaux],
                label="Cycle souhaité",
            )

        filieres = list(Filiere.objects.order_by("nom"))
        if filieres:
            self.fields["choix_filiere"] = forms.ChoiceField(
                choices=[(f.nom.upper(), f.nom) for f in filieres],
                label="Filière principale",
            )
            self.fields["alternative_filiere"] = forms.ChoiceField(
                choices=[("", "— Aucune —")] + [(f.nom.upper(), f.nom) for f in filieres],
                required=False, label="Filière alternative",
            )

        self.fields["info_level"] = forms.ChoiceField(
            choices=[("", "—")] + INFO_LEVEL_CHOICES,
            required=False, label="Niveau en Informatique",
        )


class MatriculeFilter(admin.SimpleListFilter):
    """Récupère les étudiants avec / sans matricule généré."""
    title = "matricule généré"
    parameter_name = "matricule_gen"

    def lookups(self, request, model_admin):
        return (("oui", "Avec matricule"), ("non", "Sans matricule"))

    def queryset(self, request, queryset):
        if self.value() == "oui":
            return queryset.exclude(matricule__isnull=True).exclude(matricule__exact="")
        if self.value() == "non":
            from django.db.models import Q
            return queryset.filter(Q(matricule__isnull=True) | Q(matricule__exact=""))
        return queryset


@admin.register(Inscription)
class InscriptionAdmin(ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if not request.user.is_superuser:
            try:
                from django.db.models import Q
                from campus.scoped_admin import get_user_etablissements
                etabs = get_user_etablissements(request.user)
                if etabs is not None:
                    query = Q()
                    for e in etabs:
                        query |= Q(target_etablissement__iexact=e.nom)
                    qs = qs.filter(query)
            except Exception:
                pass
        return qs
    form = InscriptionAdminForm
    list_display = ('id', 'matricule', 'last_name', 'first_name', 'target_etablissement', 'annee_academique', 'statut', 'email', 'phone', 'created_at')
    list_display_links = ('id', 'matricule', 'last_name', 'first_name')
    list_editable = ('statut',)
    search_fields = ('last_name', 'first_name', 'email', 'phone', 'target_etablissement', 'annee_academique', 'student_id', 'matricule')
    list_filter = (MatriculeFilter, 'statut', 'target_etablissement', 'annee_academique', 'sexe', 'choix_cycle', 'choix_filiere', 'created_at')
    readonly_fields = ('student_id', 'matricule', 'created_at', 'sms_felicitations', 'whatsapp_history')
    date_hierarchy = 'created_at'
    list_filter_sheet = True  # Filtres dans un panneau latéral propre (Unfold)
    change_list_template = "admin/inscription/inscription/change_list.html"

    class Media:
        js = ("inscription/js/auto_statut.js",)
    # Formulaire d'édition organisé en onglets (style démo Unfold : classe "tab")
    fieldsets = (
        ("Établissement & Année", {"classes": ["tab"], "fields": ("target_etablissement", "annee_academique")}),
        ("Identité", {"classes": ["tab"], "fields": ("last_name", "first_name", "photo", "dob", "pob", "sexe",
                                 "nationalite", "phone", "email", "adresse")}),
        ("Tuteur & Situation", {"classes": ["tab"], "fields": ("tuteur", "tel_tuteur", "civil", "occupation", "profession")}),
        ("Études antérieures", {"classes": ["tab"], "fields": ("bac_serie", "bac_annee", "bac_etablissement",
                                           "dernier_etab", "dernier_annee", "dernier_option")}),
        ("Choix de formation", {"classes": ["tab"], "fields": ("choix_cycle", "choix_filiere", "alternative_filiere", "info_level")}),
        ("Validation", {"classes": ["tab"], "fields": ("statut",)}),
        ("Système", {"classes": ["tab"], "fields": ("student_id", "matricule", "created_at")}),
        ("Historique WhatsApp", {"classes": ["tab"], "fields": ("sms_felicitations", "whatsapp_history")}),
    )
    compressed_fields = True
    warn_unsaved_form = True

    # Actions standards (par sélection)
    actions = ['export_to_excel', 'valider_inscriptions', 'rejeter_inscriptions', 'generer_matricules']

    @admin.action(description="Valider les inscriptions (sélection)")
    def valider_inscriptions(self, request, queryset):
        n = 0
        for ins in queryset:
            if ins.statut != "VALIDEE":
                ins.statut = "VALIDEE"
                ins.save()  # déclenche le SMS de félicitations + matricule auto
                n += 1
        self.message_user(request, f"{n} inscription(s) validée(s) — matricules générés, SMS envoyés.")

    @admin.action(description="Générer les matricules manquants (sélection)")
    def generer_matricules(self, request, queryset):
        n = 0
        for ins in queryset.filter(statut="VALIDEE", matricule__isnull=True):
            ins.save()  # save() génère le matricule si VALIDEE
            n += 1
        self.message_user(request, f"{n} matricule(s) généré(s).")

    def whatsapp_history(self, obj):
        from django.utils.html import escape
        from django.utils.safestring import mark_safe
        from campus.models import MessageLog
        from campus.whatsapp import normalize_number

        numeros = {normalize_number(x) for x in (obj.phone, obj.tel_tuteur)}
        numeros.discard(None)
        if not numeros:
            return "—"
        logs = MessageLog.objects.filter(to__in=numeros).order_by('-created_at')[:20]
        if not logs:
            return "Aucun message envoyé pour ces numéros."
        rows = "".join(
            f"<div style='margin-bottom:6px'>[{l.created_at:%d/%m/%Y %H:%M}] "
            f"<b>{escape(l.to)}</b> — {l.get_status_display()}<br>{escape(l.message[:200])}</div>"
            for l in logs
        )
        return mark_safe(f"<div>{rows}</div>")
    whatsapp_history.short_description = "Historique WhatsApp"

    @admin.action(description="Rejeter les inscriptions (sélection)")
    def rejeter_inscriptions(self, request, queryset):
        queryset.update(statut="REJETEE")
    
    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('export-excel-global/', self.admin_site.admin_view(self.export_all_view), name='inscription_export_excel_global'),
        ]
        return custom_urls + urls

    def export_all_view(self, request):
        # Récupérer le queryset filtré actuel
        from django.contrib.admin.views.main import ChangeList
        
        list_display = self.get_list_display(request)
        list_display_links = self.get_list_display_links(request, list_display)
        list_filter = self.get_list_filter(request)
        search_fields = self.get_search_fields(request)
        
        cl = ChangeList(
            request, self.model, list_display, list_display_links,
            list_filter, self.date_hierarchy, search_fields,
            self.list_select_related, self.list_per_page, self.list_max_show_all,
            self.list_editable, self, self.sortable_by, self.search_help_text
        )
        queryset = cl.get_queryset(request)
        return self._generate_excel_response(queryset, filename="export_complet_filtré.xlsx")

    @admin.action(description="Exporter en Excel (Sélection)")
    def export_to_excel(self, request, queryset):
        return self._generate_excel_response(queryset)

    def export_all_to_excel(self, request):
        # Plus utilisé
        pass

    def _generate_excel_response(self, queryset, filename="inscriptions_export.xlsx"):
        # Création du classeur Excel
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Inscriptions"

        # En-têtes
        headers = [
            'Nom', 'Prénom', 'Etablissement', 'Année', 'Date Naissance', 'Lieu Naissance',
            'Sexe', 'Nationalité', 'Téléphone', 'Email', 'Adresse', 'Tuteur', 'Tél Tuteur',
            'Série BAC', 'Année BAC', 'Etablissement BAC', 'Cycle Choisi', 'Filière principale',
            'Filière alternative', 'Date Inscription'
        ]
        ws.append(headers)

        # Données
        for obj in queryset:
            ws.append([
                obj.last_name, obj.first_name, obj.target_etablissement, obj.annee_academique,
                obj.dob.strftime('%d/%m/%Y') if obj.dob else '', obj.pob,
                obj.sexe, obj.nationalite, obj.phone, obj.email, obj.adresse, obj.tuteur, obj.tel_tuteur,
                obj.bac_serie, obj.bac_annee, obj.bac_etablissement, obj.choix_cycle, obj.choix_filiere,
                obj.alternative_filiere, obj.created_at.strftime('%d/%m/%Y %H:%M')
            ])

        # Préparation de la réponse HTTP
        response = HttpResponse(
            content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        wb.save(response)
        return response

@admin.register(FormConfig)
class FormConfigAdmin(ModelAdmin):
    list_display = ('apercu', 'title', 'annee_academique', 'is_active')
    list_filter = ('is_active', 'annee_academique')
    search_fields = ('title', 'school_name')
    readonly_fields = ('logo_preview', 'side_preview', 'qr1_preview', 'qr2_preview')
    change_list_template = "admin/inscription/formconfig/change_list.html"
    # Tout le contenu de la fiche d'inscription (PDF + form web) est modifiable ici
    fieldsets = (
        ("Fiche d'inscription (en-tête PDF)", {
            "fields": ("title", "annee_academique", "is_active", "logo",
                       "school_name", "school_agreement", "school_address",
                       "school_phone", "school_whatsapp", "school_website"),
        }),
        ("Formulaire web / visuels", {
            "fields": ("side_image", "app_download_url",
                       "qrcode_app", "qrcode_app_alternative"),
        }),
        ("Couleurs du site d'inscription", {
            "description": "Appliquées aux boutons et éléments colorés du formulaire web (inscription/index.html). Format hexadécimal, ex : #1a6b3c.",
            "fields": ("primary_color", "primary_dark", "accent_color"),
        }),
        ("Aperçus", {
            "fields": ("logo_preview", "side_preview", "qr1_preview", "qr2_preview"),
        }),
    )

    def _img(self, f, height=80):
        from django.utils.html import format_html
        if f:
            return format_html('<img src="{}" style="height:{}px;border-radius:8px;object-fit:contain;background:#f5f5f5;padding:4px">', f.url, height)
        return "—"

    def apercu(self, obj):
        return self._img(obj.logo, 40)
    apercu.short_description = "Logo"

    def logo_preview(self, obj):
        return self._img(obj.logo)
    logo_preview.short_description = "Aperçu logo"

    def side_preview(self, obj):
        return self._img(obj.side_image)
    side_preview.short_description = "Aperçu image latérale"

    def qr1_preview(self, obj):
        return self._img(obj.qrcode_app)
    qr1_preview.short_description = "Aperçu QR Code App 1"

    def qr2_preview(self, obj):
        return self._img(obj.qrcode_app_alternative)
    qr2_preview.short_description = "Aperçu QR Code App 2"

    def changelist_view(self, request, extra_context=None):
        latest = Inscription.objects.order_by('-created_at').first()
        extra_context = extra_context or {}
        extra_context['latest_inscription_id'] = latest.pk if latest else None
        return super().changelist_view(request, extra_context=extra_context)
