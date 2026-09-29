from django import forms
from django.contrib import admin
from django.utils.html import format_html
from unfold.admin import ModelAdmin
from unfold.decorators import action, display
from .models import (Annonce, Cours, CampusApp, Notification, Etablissement,
                     Niveau, Filiere, TarifScolarite, HeroImage, Resultat, Examen, SessionExamen, Transaction, Paiement,
                     CalendrierAcademique, SiteWeb, AppBranding, OnboardingSlide, AssistantIA, ThemeConfig,
                     AnneeAcademique, Employe, BulletinPaie, PaiementScolarite, MessageLog,
                     ProfilEtablissement)
from .scoped_admin import EtablissementScopedAdminMixin, get_user_etablissement

admin.site.site_header = "ESTIM Campus — Administration"
admin.site.site_title = "ESTIM Admin"
admin.site.index_title = "Gestion du campus"


def _thumb(url, height=40):
    if url:
        return format_html('<img src="{}" style="height:{}px;border-radius:6px;object-fit:cover">', url, height)
    return "—"

@admin.register(Transaction)
class TransactionAdmin(ModelAdmin):
    list_display = ('payer_matricule', 'target_matricule', 'amount', 'status', 'transaction_ref', 'created_at')
    list_filter = ('status', 'session')
    search_fields = ('payer_matricule', 'target_matricule', 'transaction_ref')
    autocomplete_fields = ('session',)

@admin.register(Paiement)
class PaiementAdmin(ModelAdmin):
    list_display = ('payer_matricule', 'target_matricule', 'reference', 'amount', 'created_at')
    list_filter = ('session',)
    search_fields = ('payer_matricule', 'target_matricule', 'reference')
    readonly_fields = ('created_at',)
    autocomplete_fields = ('session',)

@admin.register(SessionExamen)
class SessionExamenAdmin(ModelAdmin):
    list_display = ('nom', 'is_active', 'results_available', 'created_at')
    list_filter = ('is_active', 'results_available')
    search_fields = ('nom',)

class ExamenAdminForm(forms.ModelForm):
    """Matière : sélecteur alimenté par les matières des cours (sans doublon)."""

    class Meta:
        model = Examen
        fields = "__all__"

    class Media:
        css = {"all": ("campus/css/matiere_select.css",)}
        js = ("campus/js/matiere_select.js",)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        matieres = sorted({m for m in Cours.objects.values_list("matiere", flat=True) if m})
        if matieres:
            choices = [(m.upper(), m) for m in matieres]
            current = (self.instance.matiere or "") if self.instance and self.instance.pk else ""
            if current and current.upper() not in [c[0] for c in choices]:
                choices = [(current.upper(), current)] + choices
            self.fields["matiere"] = forms.ChoiceField(choices=choices, label="Matière")


@admin.register(Examen)
class ExamenAdmin(EtablissementScopedAdminMixin, ModelAdmin):
    form = ExamenAdminForm
    list_display = ('matiere', 'type', 'date', 'heure', 'salle', 'niveau', 'etablissement')
    list_filter = ('etablissement', 'niveau', 'filiere', 'type', 'date')
    search_fields = ('matiere', 'salle')
    autocomplete_fields = ('etablissement', 'niveau', 'filiere')
    list_filter_sheet = True
    ordering = ('date', 'heure')
    fieldsets = (
        ("Affiliation (dropdowns)", {"classes": ["tab"], "fields": ("etablissement", "niveau", "filiere")}),
        ("Examen", {"classes": ["tab"], "fields": ("matiere", "type", "date", "heure", "salle")}),
    )
    compressed_fields = True
    warn_unsaved_form = True

@admin.register(Resultat)
class ResultatAdmin(ModelAdmin):
    list_display = ('matricule', 'nom_etudiant', 'session', 'moyenne', 'admis', 'sms_envoye')
    list_filter = ('session', 'admis', 'sms_envoye')
    search_fields = ('matricule', 'nom_etudiant')
    readonly_fields = ('sms_envoye',)
    autocomplete_fields = ('session',)
    change_list_template = "admin/campus/resultat/change_list.html"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('import-excel/', self.admin_site.admin_view(self.import_excel_view), name='campus_resultat_import_excel'),
            path('modele-excel/', self.admin_site.admin_view(self.download_template_view), name='campus_resultat_template'),
        ]
        return custom_urls + urls

    def download_template_view(self, request):
        import io
        import pandas as pd
        from django.http import HttpResponse
        df = pd.DataFrame(columns=['Matricule', 'Nom', 'Moyenne', 'Admis', 'Maths', 'Anglais', 'Physique'])
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='Resultats')
        output.seek(0)
        response = HttpResponse(output.read(), content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        response['Content-Disposition'] = 'attachment; filename="modele_resultats.xlsx"'
        return response

    def import_excel_view(self, request):
        import pandas as pd
        from django.contrib import messages
        from django.shortcuts import redirect, render
        if request.method == 'POST' and request.FILES.get('file'):
            session_id = request.POST.get('session_id')
            if not session_id:
                messages.error(request, "Veuillez sélectionner une session.")
                return redirect('.')
            try:
                session = SessionExamen.objects.get(id=session_id)
                df = pd.read_excel(request.FILES['file'])
                count = 0
                for _, row in df.iterrows():
                    matricule = str(row.get('Matricule', '')).strip().upper()
                    nom = str(row.get('Nom', '')).strip()
                    if not matricule or not nom or matricule == 'NAN':
                        continue
                    moyenne = row.get('Moyenne', 0)
                    if pd.isna(moyenne):
                        moyenne = 0
                    admis_val = str(row.get('Admis', '')).strip().lower()
                    admis = admis_val in ['oui', 'yes', 'true', '1', 'admis']
                    details = {}
                    for col in df.columns:
                        if col not in ['Matricule', 'Nom', 'Moyenne', 'Admis'] and pd.notnull(row[col]):
                            details[col] = str(row[col])
                    Resultat.objects.update_or_create(
                        matricule=matricule,
                        session=session,
                        defaults={'nom_etudiant': nom, 'moyenne': moyenne, 'admis': admis, 'details_notes': details},
                    )
                    count += 1
                messages.success(request, f"{count} résultat(s) importé(s) dans « {session.nom} ».")
                return redirect('..')
            except SessionExamen.DoesNotExist:
                messages.error(request, "Session introuvable.")
            except Exception as e:
                messages.error(request, f"Erreur lors de l'importation : {e}")
            return redirect('.')
        from django.db.models import Count
        # Toutes les sessions, mais les vides (sans résultats) en premier
        sessions = SessionExamen.objects.annotate(nb_resultats=Count('resultats')).order_by('nb_resultats', '-created_at')
        context = {
            **self.admin_site.each_context(request),
            'sessions': sessions,
            'title': 'Importer des résultats',
        }
        return render(request, 'admin/campus/resultat/import_excel.html', context)

@admin.register(Etablissement)
class EtablissementAdmin(ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        etab = get_user_etablissement(request.user)
        if etab is not None:
            qs = qs.filter(pk=etab.pk)
        return qs

    def has_add_permission(self, request):
        # Un admin d'établissement ne crée pas d'établissement
        if get_user_etablissement(request.user) is not None:
            return False
        return super().has_add_permission(request)

    def has_delete_permission(self, request, obj=None):
        if get_user_etablissement(request.user) is not None:
            return False
        return super().has_delete_permission(request, obj)

    list_display = ('apercu', 'nom')
    search_fields = ('nom',)
    readonly_fields = ('apercu',)
    fieldsets = (
        (None, {"fields": ("nom", "apercu", "image", "adresse", "agrement")}),
    )

    def apercu(self, obj):
        return _thumb(obj.image.url if obj.image else None, 50)
    apercu.short_description = "Aperçu"

@admin.register(Niveau)
class NiveauAdmin(ModelAdmin):
    list_display = ('nom',)
    list_display_links = ('nom',)
    search_fields = ('nom',)

@admin.register(Filiere)
class FiliereAdmin(ModelAdmin):
    list_display = ('nom', 'montant_scolarite')
    list_editable = ('montant_scolarite',)
    list_display_links = ('nom',)
    search_fields = ('nom',)

@admin.register(TarifScolarite)
class TarifScolariteAdmin(ModelAdmin):
    list_display = ('filiere', 'niveau', 'montant')
    list_filter = ('filiere', 'niveau')
    list_editable = ('montant',)
    autocomplete_fields = ('filiere', 'niveau')
    search_fields = ('filiere__nom', 'niveau__nom')

@admin.register(AnneeAcademique)
class AnneeAcademiqueAdmin(ModelAdmin):
    list_display = ('nom', 'mois_debut', 'mois_fin', 'is_active')
    list_filter = ('is_active',)
    list_editable = ('mois_debut', 'mois_fin', 'is_active')
    list_display_links = ('nom',)
    search_fields = ('nom',)

@admin.register(Annonce)
class AnnonceAdmin(ModelAdmin):
    list_display = ('apercu', 'title', 'type', 'date')
    list_filter = ('type',)
    search_fields = ('title', 'description')
    # Unfold options
    compressed_fields = True  # Formulaire plus compact
    warn_unsaved_form = True  # Alerte si on quitte sans sauver
    change_list_template = "admin/campus/annonce/change_list.html"

    def apercu(self, obj):
        return _thumb(obj.get_image_url, 40)
    apercu.short_description = "Aperçu"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('apercu/', self.admin_site.admin_view(self.preview_view), name='campus_annonce_preview'),
        ]
        return custom_urls + urls

    def preview_view(self, request):
        from django.shortcuts import render
        annonces = Annonce.objects.all().order_by('-date')
        items = []
        for a in annonces:
            img = a.get_image_url
            if img and not img.startswith('http'):
                img = request.build_absolute_uri(img)
                if 'alwaysdata.net' in img:
                    img = img.replace('http://', 'https://')
            items.append({
                'id': a.id,
                'title': a.title,
                'description': a.description,
                'type': a.type,
                'date': a.date,
                'image': img,
            })
        context = {
            **self.admin_site.each_context(request),
            'annonces': items,
            'title': 'Prévisualisation des annonces',
        }
        return render(request, 'admin/campus/annonce/preview.html', context)

class JourFilter(admin.SimpleListFilter):
    title = "jour de la semaine"
    parameter_name = "jour"

    def lookups(self, request, model_admin):
        from .models import Cours
        return Cours.DAY_CHOICES

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(jours__contains=str(int(self.value())))
        return queryset


class CoursForm(forms.ModelForm):
    """Jours de la semaine en cases à cocher (sélection multiple)."""
    jours_multi = forms.MultipleChoiceField(
        choices=[], widget=forms.CheckboxSelectMultiple,
        label="Jours de la semaine", required=False,
    )

    class Meta:
        model = Cours
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['jours_multi'].choices = Cours.DAY_CHOICES
        if self.instance and self.instance.pk and self.instance.jours:
            self.fields['jours_multi'].initial = [str(j) for j in self.instance.get_jours_list()]
        else:
            self.fields['jours_multi'].initial = ['1']

    def save(self, commit=True):
        selected = sorted({int(x) for x in self.cleaned_data.get('jours_multi', []) if str(x).isdigit()})
        self.instance.jours = ",".join(str(x) for x in selected) if selected else "1"
        return super().save(commit=commit)


@admin.register(Cours)
class CoursAdmin(EtablissementScopedAdminMixin, ModelAdmin):
    form = CoursForm
    list_display = ('matiere', 'niveau', 'etablissement', 'filiere', 'enseignant', 'jours_display', 'heure')
    list_filter = ('etablissement', 'niveau', 'filiere', JourFilter)
    search_fields = ('matiere', 'prof', 'salle')
    autocomplete_fields = ('etablissement', 'niveau', 'filiere', 'enseignant')
    list_filter_sheet = True # Filtres dans un panneau latéral propre
    ordering = ('jours', 'heure')
    fieldsets = (
        ("Affiliation (dropdowns)", {"classes": ["tab"], "fields": ("etablissement", "niveau", "filiere", "enseignant")}),
        ("Cours", {"classes": ["tab"], "fields": ("matiere", "prof", "salle", "jours_multi", "heure")}),
    )
    compressed_fields = True
    warn_unsaved_form = True

    def jours_display(self, obj):
        return obj.get_jours_display()
    jours_display.short_description = "Jours"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('calendrier/', self.admin_site.admin_view(self.calendar_view), name='campus_cours_calendrier'),
            path('calendrier-json/', self.admin_site.admin_view(self.calendar_json), name='campus_cours_calendrier_json'),
            path('calendrier-deplacer/', self.admin_site.admin_view(self.calendar_move), name='campus_cours_calendrier_move'),
        ]
        return custom_urls + urls

    def calendar_view(self, request):
        from django.shortcuts import render
        from django.utils import timezone
        from .scolarite import periode_annee

        annee = AnneeAcademique.objects.filter(is_active=True).first()
        debut, fin = periode_annee(annee)
        today = timezone.localdate()
        # S'il y a une année active, on borne à sa période (hors période = rien).
        # S'il n'y en a aucune, on affiche sans borne.
        dans_periode = True if annee is None else bool(debut and fin and debut <= today <= fin)
        context = {
            **self.admin_site.each_context(request),
            'title': 'Emploi du temps — vue calendrier',
            'etablissements': Etablissement.objects.order_by('nom'),
            'niveaux': Niveau.objects.order_by('nom'),
            'filieres': Filiere.objects.order_by('nom'),
            'annee': annee, 'debut': debut, 'fin': fin,
            'dans_periode': dans_periode,
        }
        return render(request, 'admin/campus/cours/calendar.html', context)

    def calendar_json(self, request):
        """Cours récurrents : 1 entrée par cours, répétée sur ses jours (pas de doublon).

        Si une année académique est active : borné à sa période, et hors
        période (année finie) aucun cours n'est renvoyé.
        """
        import re
        from django.http import JsonResponse
        from django.utils import timezone
        from .scolarite import periode_annee

        annee = AnneeAcademique.objects.filter(is_active=True).first()
        debut, fin = periode_annee(annee)
        # Borne de répétition seulement si la plage visible chevauche l'année.
        # Hors chevauchement (ex : vacances, année finie) : semaine type sans borne.
        borner = False
        if annee is not None and debut and fin:
            from datetime import date as _date

            try:
                vis_start = _date.fromisoformat((request.GET.get('start') or '')[:10])
            except ValueError:
                vis_start = None
            try:
                vis_end = _date.fromisoformat((request.GET.get('end') or '')[:10])
            except ValueError:
                vis_end = None
            if vis_start is None and vis_end is None:
                borner = True
            else:
                chevauche = not ((vis_start and vis_start > fin) or (vis_end and vis_end <= debut))
                borner = chevauche

        qs = Cours.objects.select_related('etablissement', 'niveau', 'filiere')
        if request.GET.get('etablissement'):
            qs = qs.filter(etablissement_id=request.GET.get('etablissement'))
        if request.GET.get('niveau'):
            qs = qs.filter(niveau_id=request.GET.get('niveau'))
        if request.GET.get('filiere'):
            qs = qs.filter(filiere_id=request.GET.get('filiere'))

        events = []
        for c in qs:
            days = [(j % 7) for j in c.get_jours_list()]  # FullCalendar : 0=Dimanche … 6=Samedi
            heure = str(c.heure or '')
            ev = {
                'id': c.id,
                'title': f"{c.matiere} — {c.salle}",
                'daysOfWeek': days,
                'extendedProps': {
                    'prof': c.prof, 'salle': c.salle, 'heure': c.heure,
                    'jours': c.get_jours_display(),
                    'filiere': c.filiere.nom if c.filiere_id else '',
                    'niveau': c.niveau.nom if c.niveau_id else '',
                },
            }
            # Formats acceptés : "07h30-09h30" ou "07:30-09:30" (ou heure seule)
            m = re.match(r'\s*(\d{1,2})[h:](\d{2})\s*(?:-\s*(\d{1,2})[h:](\d{2}))?', heure)
            if m:
                ev['startTime'] = f"{int(m.group(1)):02d}:{m.group(2)}:00"
                if m.group(3):
                    ev['endTime'] = f"{int(m.group(3)):02d}:{m.group(4)}:00"
                else:
                    ev['duration'] = '02:00'
            if borner:
                # Borne de répétition = année académique (ex : tous les lundis de l'année).
                # endRecur est exclus : +1 jour pour inclure le dernier jour.
                from datetime import timedelta
                ev['startRecur'] = debut.isoformat()
                ev['endRecur'] = (fin + timedelta(days=1)).isoformat()
            events.append(ev)
        return JsonResponse(events, safe=False)

    def calendar_move(self, request):
        """Drag & drop : déplace l'occurrence (jour 1-7 + heure HH:MM) sur le cours.

        Le jour d'origine est remplacé par le nouveau jour ; l'heure de début
        est remplacée en conservant la durée (format "07h30-09h30").
        """
        import re
        from django.http import JsonResponse

        if request.method != 'POST':
            return JsonResponse({'error': 'POST requis'}, status=405)
        cours = Cours.objects.filter(pk=request.POST.get('id')).first()
        if not cours:
            return JsonResponse({'error': 'Cours introuvable'}, status=404)
        try:
            jour_origine = int(request.POST.get('jour_origine', 0))
            jour_nouveau = int(request.POST.get('jour_nouveau', 0))
        except (TypeError, ValueError):
            return JsonResponse({'error': 'Jour invalide'}, status=400)
        if not 1 <= jour_nouveau <= 7:
            return JsonResponse({'error': 'Jour invalide'}, status=400)

        jours = cours.get_jours_list()
        if jour_origine in jours:
            jours = [j for j in jours if j != jour_origine]
        if jour_nouveau not in jours:
            jours.append(jour_nouveau)
        cours.jours = ",".join(str(j) for j in sorted(jours))

        heure = (request.POST.get('heure') or '').strip()  # "HH:MM"
        m_new = re.match(r'(\d{1,2}):(\d{2})', heure)
        m_old = re.match(r'\s*(\d{1,2})[h:](\d{2})\s*(?:-\s*(\d{1,2})[h:](\d{2}))?', str(cours.heure or ''))
        if m_new and m_old:
            ns, nm = int(m_new.group(1)), m_new.group(2)
            m_fin = re.match(r'(\d{1,2}):(\d{2})', (request.POST.get('heure_fin') or '').strip())
            if m_fin:
                cours.heure = f"{ns:02d}h{nm}-{int(m_fin.group(1)):02d}h{m_fin.group(2)}"
            else:
                duree = 120  # défaut 2h
                if m_old.group(3):
                    duree = (int(m_old.group(3)) * 60 + int(m_old.group(4))) - (int(m_old.group(1)) * 60 + int(m_old.group(2)))
                    duree = duree if duree > 0 else 120
                fin = ns * 60 + int(nm) + duree
                cours.heure = f"{ns:02d}h{nm}-{fin // 60:02d}h{fin % 60:02d}"
        cours.save()
        return JsonResponse({'ok': True, 'jours': cours.jours, 'heure': cours.heure})


@admin.register(CampusApp)
class CampusAppAdmin(ModelAdmin):
    list_display = ('apercu', 'title', 'route')
    search_fields = ('title',)

    def apercu(self, obj):
        if obj.image_url:
            return _thumb(obj.image_url, 40)
        return format_html('<span class="material-symbols-outlined">{}</span>', obj.icon_name or 'apps')
    apercu.short_description = "Aperçu"

@admin.register(HeroImage)
class HeroImageAdmin(ModelAdmin):
    list_display = ('apercu', 'title', 'is_active', 'created_at')

    def apercu(self, obj):
        return _thumb(obj.get_image_url, 40)
    apercu.short_description = "Aperçu"

@admin.register(Notification)
class NotificationAdmin(ModelAdmin):
    list_display = ('title', 'notification_type', 'target_matricule', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read')
    search_fields = ('title', 'message', 'target_matricule')
    readonly_fields = ('created_at',)
    autocomplete_fields = ('annonce',)

@admin.register(CalendrierAcademique)
class CalendrierAcademiqueAdmin(ModelAdmin):
    list_display = ('title', 'date_debut', 'date_fin', 'is_important')
    list_filter = ('is_important', 'date_debut')
    search_fields = ('title', 'description')
    change_list_template = "admin/campus/calendrieracademique/change_list.html"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('calendrier/', self.admin_site.admin_view(self.calendar_view), name='campus_calendrier_calendar'),
        ]
        return custom_urls + urls

    def calendar_view(self, request):
        from django.shortcuts import render
        context = {
            **self.admin_site.each_context(request),
            'title': 'Calendrier académique',
        }
        return render(request, 'admin/campus/calendrieracademique/calendar.html', context)

@admin.register(SiteWeb)
class SiteWebAdmin(ModelAdmin):
    list_display = ('apercu', 'url')
    search_fields = ('title', 'url')
    change_list_template = "admin/campus/siteweb/change_list.html"
    actions_row = ["modifier_site", "ouvrir_site"]

    @action(description="Modifier", url_path="modifier")
    def modifier_site(self, request, object_id):
        from django.shortcuts import redirect
        from django.urls import reverse
        return redirect(reverse("admin:campus_siteweb_change", args=[object_id]))

    def has_modifier_site_permission(self, request):
        return True

    class Media:
        css = {"all": ("campus/css/siteweb_preview.css",)}

    @action(description="Ouvrir le site", url_path="ouvrir-site", attrs={"target": "_blank"})
    def ouvrir_site(self, request, object_id):
        from django.shortcuts import get_object_or_404, redirect
        site = get_object_or_404(SiteWeb, pk=object_id)
        return redirect(site.url)

    def has_ouvrir_site_permission(self, request):
        return True

    @display(description="Aperçu")
    def apercu(self, obj):
        from django.urls import reverse

        change_url = reverse("admin:campus_siteweb_change", args=[obj.pk])
        # Facebook & co interdisent l'iframe (X-Frame-Options: DENY) :
        # carte-lien à la place du carré vide.
        if "facebook.com" in (obj.url or ""):
            return format_html(
                '<span class="sw-card"><span class="sw-frame">'
                '<a class="sw-fb" href="{}" target="_blank">Facebook ↗</a></span>'
                '<span class="sw-title"><a href="{}">{}</a></span></span>',
                obj.url, change_url, obj.title,
            )
        # Miniature + titre cliquable vers la fiche (remplace la colonne "Nom du site").
        return format_html(
            '<span class="sw-card"><span class="sw-frame">'
            '<iframe src="{}" title="Aperçu — {}" loading="lazy" sandbox="allow-scripts allow-same-origin"></iframe>'
            '</span><span class="sw-title"><a href="{}">{}</a></span></span>',
            obj.url, obj.title, change_url, obj.title,
        )

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('apercu/', self.admin_site.admin_view(self.preview_view), name='campus_siteweb_preview'),
        ]
        return custom_urls + urls

    def preview_view(self, request):
        from django.shortcuts import render
        context = {
            **self.admin_site.each_context(request),
            'sites': SiteWeb.objects.all().order_by('title'),
            'title': 'Prévisualisation des sites web',
        }
        return render(request, 'admin/campus/siteweb/preview.html', context)

@admin.register(AppBranding)
class AppBrandingAdmin(ModelAdmin):
    list_display = ('app_name', 'is_active', 'updated_at')
    list_filter = ('is_active',)
    search_fields = ('app_name',)

@admin.register(AssistantIA)
class AssistantIAAdmin(ModelAdmin):
    list_display = ('nom', 'is_active', 'updated_at')
    list_filter = ('is_active',)
    search_fields = ('nom',)

@admin.register(OnboardingSlide)
class OnboardingSlideAdmin(ModelAdmin):
    list_display = ('ordre', 'title', 'is_active', 'created_at')
    list_display_links = ('title',)
    list_filter = ('is_active',)
    search_fields = ('title', 'description')
    list_editable = ('ordre', 'is_active')
    ordering = ('ordre',)

PRESET_COLORS = [
    ("#1a6b3c", "Vert ESTIM"),
    ("#7c3aed", "Violet"),
    ("#2563eb", "Bleu"),
    ("#dc2626", "Rouge"),
    ("#ea580c", "Orange"),
    ("#ca8a04", "Or"),
    ("#0d9488", "Turquoise"),
    ("#db2777", "Rose"),
    ("#111827", "Noir"),
]


class ThemeConfigForm(forms.ModelForm):
    preset = forms.ChoiceField(
        choices=[("", "— Choisir une couleur prédéfinie —")] + [(c, f"{label} ({c})") for c, label in PRESET_COLORS],
        required=False, label="Palette prédéfinie",
        help_text="Sélectionne une couleur : elle remplit le champ ci-dessous. Ou utilise le sélecteur.",
    )

    class Meta:
        from .models import ThemeConfig as _TC
        model = _TC
        fields = "__all__"
        widgets = {
            "primary_color": forms.TextInput(attrs={"type": "color", "style": "width:80px;height:40px;padding:2px;"}),
            "accent_color": forms.TextInput(attrs={"type": "color", "style": "width:80px;height:40px;padding:2px;"}),
        }
        labels = {"primary_color": "Couleur principale (sélecteur)", "accent_color": "Couleur d'accent (sélecteur)"}

    class Media:
        js = ("campus/js/theme_preset.js",)


@admin.register(ThemeConfig)
class ThemeConfigAdmin(ModelAdmin):
    form = ThemeConfigForm
    list_display = ('pastille', 'pastille_accent', 'name', 'primary_color', 'accent_color', 'is_active', 'updated_at')
    list_filter = ('is_active',)
    search_fields = ('name',)
    fieldsets = (
        ("Thème", {"fields": ("name", "is_active")}),
        ("Couleurs modifiables", {"fields": ("preset", "primary_color", "accent_color")}),
    )

    def pastille(self, obj):
        return format_html('<span style="display:inline-block;width:28px;height:28px;border-radius:8px;background:{};border:1px solid #ccc"></span>', obj.primary_color)
    pastille.short_description = "Principale"

    def pastille_accent(self, obj):
        return format_html('<span style="display:inline-block;width:28px;height:28px;border-radius:8px;background:{};border:1px solid #ccc"></span>', obj.accent_color)
    pastille_accent.short_description = "Accent"


@admin.register(Employe)
class EmployeAdmin(EtablissementScopedAdminMixin, ModelAdmin):
    list_display = ('apercu', 'last_name', 'first_name', 'type_personnel', 'fonction', 'filiere', 'salaire_base', 'compte', 'statut')
    list_filter = ('type_personnel', 'statut', 'etablissement', 'filiere')
    search_fields = ('last_name', 'first_name', 'phone', 'email', 'fonction')
    autocomplete_fields = ('etablissement', 'filiere', 'user')
    readonly_fields = ('created_at',)
    list_filter_sheet = True
    change_form_template = "admin/campus/employe/change_form.html"
    fieldsets = (
        ("Identité", {"fields": ("type_personnel", "last_name", "first_name", "photo", "sexe", "phone", "email", "adresse")}),
        ("Poste & affectation", {"fields": ("fonction", "etablissement", "filiere", "date_embauche", "statut")}),
        ("Compte de connexion", {"fields": ("user",)}),
        ("Salaire", {"fields": ("salaire_base",)}),
        ("Documents administratifs", {"fields": ("cv", "diplome", "contrat", "piece_identite")}),
        ("Système", {"fields": ("created_at",)}),
    )
    compressed_fields = True
    warn_unsaved_form = True

    def apercu(self, obj):
        return _thumb(obj.photo.url if obj.photo else None, 40)
    apercu.short_description = "Photo"

    def compte(self, obj):
        return obj.user.username if obj.user else "—"
    compte.short_description = "Compte"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('<int:pk>/fiche/', self.admin_site.admin_view(self.fiche_view), name='campus_employe_fiche'),
        ]
        return custom_urls + urls

    def fiche_view(self, request, pk):
        from django.shortcuts import get_object_or_404, render
        employe = get_object_or_404(Employe, pk=pk)
        context = {
            **self.admin_site.each_context(request),
            'employe': employe,
            'cours': Cours.objects.filter(enseignant=employe).order_by('jours', 'heure'),
            'title': f"Fiche employé — {employe}",
        }
        return render(request, 'admin/campus/employe/fiche.html', context)


@admin.register(BulletinPaie)
class BulletinPaieAdmin(ModelAdmin):
    list_display = ('employe', 'mois', 'annee', 'salaire_base', 'primes', 'retenues', 'net_a_payer', 'verse_le')
    list_filter = ('annee', 'mois')
    search_fields = ('employe__last_name', 'employe__first_name')
    autocomplete_fields = ('employe',)
    readonly_fields = ('created_at', 'net_a_payer')
    change_form_template = "admin/campus/bulletinpaie/change_form.html"

    def net_a_payer(self, obj):
        return f"{obj.net_a_payer} FCFA"
    net_a_payer.short_description = "Net à payer"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('<int:pk>/fiche/', self.admin_site.admin_view(self.fiche_view), name='campus_bulletin_fiche'),
        ]
        return custom_urls + urls

    def fiche_view(self, request, pk):
        from django.shortcuts import get_object_or_404, render
        bulletin = get_object_or_404(BulletinPaie, pk=pk)
        context = {
            **self.admin_site.each_context(request),
            'bulletin': bulletin,
            'title': f"Bulletin de paie — {bulletin}",
        }
        return render(request, 'admin/campus/bulletinpaie/fiche.html', context)


class PaiementScolariteForm(forms.ModelForm):
    """Mois limité à la période de l'année académique (début → fin en DB)."""

    class Meta:
        model = PaiementScolarite
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        from .scolarite import mois_annee_academique
        annee = None
        if self.instance and self.instance.pk and self.instance.annee_academique_id:
            annee = self.instance.annee_academique
        elif self.initial.get("annee_academique"):
            try:
                annee = AnneeAcademique.objects.filter(pk=self.initial["annee_academique"]).first()
            except Exception:
                annee = None
        if annee is None:
            annee = AnneeAcademique.objects.filter(is_active=True).first() or AnneeAcademique.objects.order_by("-nom").first()
        if annee is not None:
            from datetime import date
            mois_liste = mois_annee_academique(annee)
            self.fields["mois"].choices = [("", "— Choisir le mois —")] + [
                (str(m), label) for m, y, label in mois_liste
            ]
            self.fields["mois"].help_text = f"Période : {annee.nom} ({annee.get_mois_debut_display()} → {annee.get_mois_fin_display()})."
            if not (self.instance and self.instance.pk and self.instance.annee_academique_id):
                self.fields["annee_academique"].initial = annee.pk
            # Mois actuel pré-sélectionné s'il fait partie de la période (création uniquement).
            if not (self.instance and self.instance.pk and self.instance.mois):
                mois_actuel = date.today().month
                if any(m == mois_actuel for m, y, label in mois_liste):
                    self.fields["mois"].initial = str(mois_actuel)


@admin.register(PaiementScolarite)
class PaiementScolariteAdmin(ModelAdmin):
    form = PaiementScolariteForm
    list_display = ('reference', 'nom_etudiant', 'matricule', 'mois_concerne', 'niveau', 'filiere', 'motif', 'montant', 'methode', 'sms_badge', 'created_at')
    list_filter = ('motif', 'methode', 'sms_envoye', 'niveau', 'filiere', 'annee_academique', 'mois', 'created_at')
    search_fields = ('reference', 'nom_etudiant', 'matricule')
    readonly_fields = ('reference', 'sms_envoye', 'created_at')
    autocomplete_fields = ('niveau', 'filiere', 'annee_academique')
    date_hierarchy = 'created_at'
    change_form_template = "admin/campus/paiementscolarite/change_form.html"
    change_list_template = "admin/campus/paiementscolarite/change_list.html"
    fieldsets = (
        ("Étudiant", {"classes": ["tab"], "fields": ("matricule", "nom_etudiant", "niveau", "filiere", "phone_tuteur")}),
        ("Paiement", {"classes": ["tab"], "fields": (("annee_academique", "mois"), "motif", "montant", "methode", "recu_par")}),
        ("Suivi", {"classes": ["tab"], "fields": ("reference", "sms_envoye", "created_at")}),
    )
    compressed_fields = True
    warn_unsaved_form = True

    def mois_concerne(self, obj):
        if obj.mois:
            return f"{obj.get_mois_display()} ({obj.annee_academique.nom if obj.annee_academique_id else '—'})"
        return "—"
    mois_concerne.short_description = "Mois concerné"

    actions_row = ["imprimer_ticket"]

    @action(description="Imprimer le ticket", url_path="imprimer-ticket", attrs={"target": "_blank"})
    def imprimer_ticket(self, request, object_id):
        from django.shortcuts import redirect
        return redirect(f"{object_id}/ticket/")

    def has_imprimer_ticket_permission(self, request):
        return True

    @display(description="SMS", label={True: "success", False: "warning"})
    def sms_badge(self, obj):
        return obj.sms_envoye, "Envoyé" if obj.sms_envoye else "Non envoyé"

    actions = ['renvoyer_sms']

    @admin.action(description="Renvoyer le SMS au tuteur (sélection)")
    def renvoyer_sms(self, request, queryset):
        from .whatsapp import build_recu_message, send_tutor_message

        envoyes, echecs = 0, 0
        for p in queryset:
            if not p.phone_tuteur:
                echecs += 1
                continue
            if send_tutor_message(p.phone_tuteur, build_recu_message(p)):
                PaiementScolarite.objects.filter(pk=p.pk).update(sms_envoye=True)
                envoyes += 1
            else:
                echecs += 1
        from django.contrib import messages
        self.message_user(request, f"SMS : {envoyes} envoyé(s), {echecs} échec(s). Détail dans le Journal WhatsApp.", messages.INFO)
    mois_concerne.short_description = "Mois concerné"

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('<int:pk>/ticket/', self.admin_site.admin_view(self.ticket_view), name='campus_paiement_ticket'),
            path('rechercher-etudiant/', self.admin_site.admin_view(self.search_etudiant_view), name='campus_paiement_search'),
            path('montant-affiliation/', self.admin_site.admin_view(self.montant_affiliation_view), name='campus_paiement_montant'),
            path('mois-annee/', self.admin_site.admin_view(self.mois_annee_view), name='campus_paiement_mois'),
            path('suivi/', self.admin_site.admin_view(self.suivi_view), name='campus_paiement_suivi'),
        ]
        return custom_urls + urls

    def suivi_view(self, request):
        from collections import defaultdict
        from decimal import Decimal
        from django.db.models import Q, Sum
        from django.shortcuts import render
        from inscription.models import Inscription
        from .scolarite import STATUT_LABELS, match_affiliation, montant_attendu, periode_annee, statut_dette

        annees = AnneeAcademique.objects.all().order_by('-nom')
        annee_pk = request.GET.get('annee') or None
        try:
            annee_pk = int(annee_pk) if annee_pk else None
        except (TypeError, ValueError):
            annee_pk = None
        annee = AnneeAcademique.objects.filter(pk=annee_pk).first() if annee_pk else None
        if not annee:
            annee = AnneeAcademique.objects.filter(is_active=True).first() or annees.first()
        statut_f = request.GET.get('statut', '')
        q = request.GET.get('q', '').strip()

        debut, fin = periode_annee(annee)
        paiements = PaiementScolarite.objects.all()
        if debut and fin:
            paiements = paiements.filter(created_at__date__range=(debut, fin))
        paye_par = defaultdict(lambda: Decimal('0'))
        noms = {}
        for p in paiements.values('matricule', 'nom_etudiant').annotate(total=Sum('montant')):
            paye_par[p['matricule']] += p['total'] or 0
            noms[p['matricule']] = p['nom_etudiant']

        for r in Resultat.objects.values('matricule', 'nom_etudiant').distinct():
            noms.setdefault(r['matricule'], r['nom_etudiant'])

        niveaux = list(Niveau.objects.all())
        filieres = list(Filiere.objects.all())
        inscriptions = list(Inscription.objects.filter(statut="VALIDEE"))
        by_nom = {}
        for ins in inscriptions:
            by_nom.setdefault(f"{ins.last_name} {ins.first_name}".strip().upper(), ins)

        def find_inscription(nom):
            parts = (nom or '').split()
            if len(parts) >= 2:
                hit = by_nom.get(f"{parts[0]} {parts[-1]}".upper())
                if hit:
                    return hit
            for ins in inscriptions:
                if parts and (parts[0].upper() in ins.last_name.upper() or parts[0].upper() in ins.first_name.upper()):
                    return ins
            return None

        rows = []
        tot_attendu = tot_paye = tot_reste = Decimal('0')
        for matricule, nom in noms.items():
            if q and q.upper() not in matricule.upper() and q.upper() not in (nom or '').upper():
                continue
            ins = find_inscription(nom)
            if ins is None:
                # Suivi réservé aux étudiants à inscription validée
                continue
            niv, fil = match_affiliation(
                ins.choix_cycle if ins else '', ins.choix_filiere if ins else '',
                niveaux, filieres,
            )
            attendu = montant_attendu(niv, fil)
            paye = paye_par.get(matricule, Decimal('0'))
            statut, reste = statut_dette(attendu, paye)
            if statut_f and statut != statut_f:
                continue
            tot_attendu += attendu
            tot_paye += paye
            tot_reste += reste
            rows.append({
                'matricule': matricule, 'nom': nom,
                'niveau': niv.nom if niv else '—', 'filiere': fil.nom if fil else '—',
                'attendu': attendu, 'paye': paye, 'reste': reste,
                'statut': statut, 'statut_label': STATUT_LABELS[statut],
            })
        rows.sort(key=lambda r: (r['statut'] != 'IMPAYE', r['statut'] != 'PARTIEL', r['nom'] or ''))
        from django import forms as _forms
        from unfold.widgets import UnfoldAdminSelectWidget, UnfoldAdminTextInputWidget

        class SuiviFilterForm(_forms.Form):
            annee = _forms.ModelChoiceField(
                queryset=AnneeAcademique.objects.order_by('-nom'),
                required=False, label="Année", widget=UnfoldAdminSelectWidget,
            )
            statut = _forms.ChoiceField(
                choices=[("", "Tous")] + [(c, l) for c, l in STATUT_LABELS.items()],
                required=False, label="Statut", widget=UnfoldAdminSelectWidget,
            )
            q = _forms.CharField(
                required=False, label="Recherche",
                widget=UnfoldAdminTextInputWidget(attrs={"placeholder": "Matricule ou nom..."}),
            )

        filter_form = SuiviFilterForm(initial={
            'annee': annee.pk if annee else None, 'statut': statut_f, 'q': q,
        })
        # Données pour les composants Unfold (container / card / table / progress / navigation)
        from urllib.parse import urlencode

        def _qs(**kw):
            params = {}
            if annee:
                params['annee'] = annee.pk
            if q:
                params['q'] = q
            params.update({k: v for k, v in kw.items() if v})
            return f"?{urlencode(params)}"

        statut_nav = [{"title": "Tous", "link": _qs(), "active": not statut_f}]
        for code, label in STATUT_LABELS.items():
            statut_nav.append({"title": label, "link": _qs(statut=code), "active": statut_f == code})

        taux = round(float(tot_paye) / float(tot_attendu) * 100) if tot_attendu else 0
        cards = [
            {"title": "Attendu", "metric": f"{tot_attendu} FCFA"},
            {"title": "Encaissé", "metric": f"{tot_paye} FCFA"},
            {"title": "Dettes", "metric": f"{tot_reste} FCFA"},
            {"title": "Étudiants", "metric": str(len(rows))},
        ]
        table = {
            "headers": ["Matricule", "Nom", "Niveau", "Filière", "Attendu", "Payé", "Reste", "Statut"],
            "rows": [
                [r['matricule'], r['nom'] or '', r['niveau'], r['filiere'],
                 f"{r['attendu']}", f"{r['paye']}", f"{r['reste']}", r['statut_label']]
                for r in rows
            ],
        }
        context = {
            **self.admin_site.each_context(request),
            'title': 'Suivi des paiements',
            'annees': annees, 'annee': annee, 'debut': debut, 'fin': fin,
            'statut_f': statut_f, 'q': q, 'statuts': STATUT_LABELS,
            'rows': rows, 'tot_attendu': tot_attendu, 'tot_paye': tot_paye, 'tot_reste': tot_reste,
            'filter_form': filter_form,
            'suivi_cards': cards, 'suivi_table': table,
            'suivi_taux': taux, 'statut_nav': statut_nav,
        }
        return render(request, 'admin/campus/paiementscolarite/suivi.html', context)

    def montant_affiliation_view(self, request):
        """Retourne le montant à payer : tarif (Filière+Niveau) d'abord, sinon montant de la filière, sinon 0."""
        from django.http import JsonResponse

        montant = 0
        filiere_id = request.GET.get('filiere_id')
        niveau_id = request.GET.get('niveau_id')
        if filiere_id and niveau_id:
            tarif = TarifScolarite.objects.filter(filiere_id=filiere_id, niveau_id=niveau_id).first()
            if tarif and tarif.montant:
                return JsonResponse({'montant': str(tarif.montant)})
        if filiere_id:
            fil = Filiere.objects.filter(pk=filiere_id).first()
            if fil and fil.montant_scolarite:
                montant = fil.montant_scolarite
        return JsonResponse({'montant': str(montant)})

    def get_changeform_initial_data(self, request):
        from datetime import date
        init = {'recu_par': request.user.get_username()}
        annee = AnneeAcademique.objects.filter(is_active=True).first() or AnneeAcademique.objects.order_by('-nom').first()
        if annee:
            init['annee_academique'] = annee.pk
            # Mois actuel par défaut s'il est couvert par l'année académique.
            from .scolarite import mois_annee_academique
            mois_actuel = date.today().month
            if any(m == mois_actuel for m, y, label in mois_annee_academique(annee)):
                init['mois'] = mois_actuel
        return init

    def mois_annee_view(self, request):
        """Mois (début → fin) d'une année académique pour le dropdown du paiement."""
        from django.http import JsonResponse
        from .scolarite import mois_annee_academique
        annee = AnneeAcademique.objects.filter(pk=request.GET.get('annee_id')).first()
        if annee is None:
            annee = AnneeAcademique.objects.filter(is_active=True).first() or AnneeAcademique.objects.order_by('-nom').first()
        if annee is None:
            return JsonResponse({'mois': []})
        return JsonResponse({'mois': [
            {'num': m, 'label': label} for m, y, label in mois_annee_academique(annee)
        ]})

    def search_etudiant_view(self, request):
        from django.db.models import Q
        from django.http import JsonResponse
        from inscription.models import Inscription
        from .scolarite import match_affiliation

        def affiliation(ins):
            """Retrouve le Niveau / la Filière depuis la fiche d'inscription."""
            if not ins:
                return None, None
            return match_affiliation(ins.choix_cycle, ins.choix_filiere)

        def find_inscription(nom):
            """Retrouve la fiche d'inscription : ordre NOM Prénom puis Prénom NOM, validées d'abord."""
            parts = (nom or '').split()
            if not parts:
                return None
            queries = []
            if len(parts) >= 2:
                queries.append(Q(last_name__icontains=parts[0]) & Q(first_name__icontains=parts[-1]))
                queries.append(Q(last_name__icontains=parts[-1]) & Q(first_name__icontains=parts[0]))
            else:
                queries.append(Q(last_name__icontains=parts[0]) | Q(first_name__icontains=parts[0]))
            for query in queries:
                hit = Inscription.objects.filter(query, statut="VALIDEE").first()
                if hit:
                    return hit
            for query in queries:
                hit = Inscription.objects.filter(query).first()
                if hit:
                    return hit
            return None

        def dernier_paiement(matricule):
            """Dernier paiement connu pour ce matricule (repli : niveau, filière, tuteur)."""
            if not matricule:
                return None
            return PaiementScolarite.objects.filter(matricule__iexact=matricule).order_by('-created_at').first()

        q = request.GET.get('q', '').strip()
        if len(q) < 2:
            return JsonResponse({'results': []})
        annee_active = AnneeAcademique.objects.filter(is_active=True).first()

        def mois_payes(matricule):
            """Mois déjà payés (année active) : {mois: [{motif, reference}]}."""
            if not matricule or annee_active is None:
                return {}
            out = {}
            for p in PaiementScolarite.objects.filter(
                matricule__iexact=matricule, annee_academique=annee_active
            ).values('mois', 'motif', 'reference'):
                out.setdefault(str(p['mois']), []).append({'motif': p['motif'], 'reference': p['reference']})
            return out

        results = []
        # 1. Étudiants avec résultats (matricule officiel + nom)
        for r in Resultat.objects.filter(
            Q(matricule__icontains=q) | Q(nom_etudiant__icontains=q)
        ).order_by('nom_etudiant')[:8]:
            phone = ''
            ins = find_inscription(r.nom_etudiant)
            # Uniquement les étudiants à inscription validée
            if not ins or ins.statut != "VALIDEE":
                continue
            if ins and ins.tel_tuteur:
                phone = ins.tel_tuteur
            niv, fil = affiliation(ins)
            prev = dernier_paiement(r.matricule)
            if niv is None and prev and prev.niveau_id:
                niv = prev.niveau
            if fil is None and prev and prev.filiere_id:
                fil = prev.filiere
            if not phone and prev and prev.phone_tuteur:
                phone = prev.phone_tuteur
            results.append({
                'label': f"{r.nom_etudiant} — {r.matricule}",
                'matricule': r.matricule, 'nom': r.nom_etudiant,
                'phone': phone, 'source': 'Résultat',
                'niveau_id': niv.pk if niv else None, 'niveau_nom': niv.nom if niv else '',
                'filiere_id': fil.pk if fil else None, 'filiere_nom': fil.nom if fil else '',
                'mois_payes': mois_payes(r.matricule),
            })
        # 2. Inscrits validés uniquement (sans matricule : convention INS-<id>)
        for ins in Inscription.objects.filter(
            statut="VALIDEE",
        ).filter(
            Q(last_name__icontains=q) | Q(first_name__icontains=q) | Q(phone__icontains=q)
        ).order_by('-created_at')[:8]:
            nom = f"{ins.last_name} {ins.first_name}".strip()
            if any(x['matricule'] == f"INS-{ins.pk}" for x in results):
                continue
            niv, fil = affiliation(ins)
            phone = ins.tel_tuteur or ''
            if not phone:
                prev = PaiementScolarite.objects.filter(
                    Q(matricule__iexact=f"INS-{ins.pk}") | Q(nom_etudiant__iexact=nom)
                ).order_by('-created_at').first()
                if prev and prev.phone_tuteur:
                    phone = prev.phone_tuteur
            results.append({
                'label': f"{nom} — INS-{ins.pk} (inscription)",
                'matricule': f"INS-{ins.pk}", 'nom': nom,
                'phone': phone, 'source': 'Inscription',
                'niveau_id': niv.pk if niv else None, 'niveau_nom': niv.nom if niv else '',
                'filiere_id': fil.pk if fil else None, 'filiere_nom': fil.nom if fil else '',
                'mois_payes': mois_payes(f"INS-{ins.pk}"),
            })
        return JsonResponse({'results': results[:12]})

    def save_model(self, request, obj, form, change):
        # L'agent qui a reçu est toujours renseigné : modifiable dans le formulaire,
        # sinon rempli automatiquement avec l'utilisateur connecté.
        if not obj.recu_par:
            obj.recu_par = request.user.get_username()
        super().save_model(request, obj, form, change)

    def ticket_view(self, request, pk):
        from django.shortcuts import get_object_or_404, render
        paiement = get_object_or_404(PaiementScolarite, pk=pk)
        theme = ThemeConfig.objects.filter(is_active=True).first()
        # École : établissement de l'utilisateur si profilé, sinon premier établissement
        ecole = None
        profil = ProfilEtablissement.objects.filter(user=request.user).first()
        if profil:
            ecole = profil.etablissements.order_by('nom').first()
        if ecole is None:
            ecole = Etablissement.objects.order_by('nom').first()
        context = {
            **self.admin_site.each_context(request),
            'paiement': paiement,
            'title': f"Ticket — {paiement.reference}",
            'couleur': (theme.primary_color if theme else '#1a6b3c'),
            'accent': (theme.accent_color if theme and theme.accent_color else '#ca8a04'),
            'ecole': ecole,
        }
        return render(request, 'admin/campus/paiementscolarite/ticket.html', context)


@admin.register(ProfilEtablissement)
class ProfilEtablissementAdmin(ModelAdmin):
    list_display = ('user', 'ecoles', 'nb_ecoles')
    list_filter = ('etablissements',)
    search_fields = ('user__username', 'etablissements__nom')
    autocomplete_fields = ('user',)
    filter_horizontal = ('etablissements',)

    def ecoles(self, obj):
        return ", ".join(e.nom for e in obj.etablissements.all()) or "—"
    ecoles.short_description = "Écoles gérées"

    def nb_ecoles(self, obj):
        return obj.etablissements.count()
    nb_ecoles.short_description = "Nb"

    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_module_permission(self, request):
        return request.user.is_superuser

    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path('creer/', self.admin_site.admin_view(self.creer_compte_view), name='campus_compte_creer'),
        ]
        return custom_urls + urls

    def creer_compte_view(self, request):
        """Crée un compte admin : user + employé lié + écoles gérées."""
        from django.contrib import messages
        from django.contrib.auth.models import User
        from django.shortcuts import redirect, render

        if not request.user.is_superuser:
            messages.error(request, "Réservé au super-administrateur.")
            return redirect('..')
        if request.method == 'POST':
            username = (request.POST.get('username') or '').strip()
            password = request.POST.get('password') or ''
            employe_id = request.POST.get('employe_id') or None
            etab_ids = [i for i in request.POST.getlist('etablissements') if str(i).isdigit()]
            if not username or not password:
                messages.error(request, "Identifiant et mot de passe requis.")
            elif User.objects.filter(username=username).exists():
                messages.error(request, f"Le compte « {username} » existe déjà.")
            elif not etab_ids:
                messages.error(request, "Coche au moins une école gérée.")
            else:
                employe = Employe.objects.filter(pk=employe_id).first() if employe_id else None
                user = User.objects.create_user(
                    username=username, password=password, is_staff=True,
                    first_name=(employe.first_name if employe else ''),
                    last_name=(employe.last_name if employe else ''),
                    email=(employe.email if employe and employe.email else ''),
                )
                # Droits : gérer les données campus + inscriptions (le scoping
                # limite ensuite à ses écoles via EtablissementScopedAdminMixin)
                from django.contrib.auth.models import Permission
                user.user_permissions.set(
                    Permission.objects.filter(content_type__app_label__in=['campus', 'inscription'])
                )
                if employe:
                    employe.user = user
                    employe.save(update_fields=['user'])
                profil, _ = ProfilEtablissement.objects.get_or_create(user=user)
                profil.etablissements.set(etab_ids)
                messages.success(
                    request,
                    f"Compte « {username} » créé"
                    f"{f' (lié à {employe})' if employe else ''} — "
                    f"{profil.etablissements.count()} école(s).",
                )
                return redirect('..')
        context = {
            **self.admin_site.each_context(request),
            'title': 'Créer un compte admin',
            'employes': Employe.objects.filter(user__isnull=True).order_by('last_name', 'first_name'),
            'etablissements': Etablissement.objects.order_by('nom'),
        }
        return render(request, 'admin/campus/profiletablissement/creer.html', context)


@admin.register(MessageLog)
class MessageLogAdmin(ModelAdmin):
    list_display = ('to', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('to', 'message')
    readonly_fields = ('to', 'message', 'status', 'response', 'created_at')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
