from django.conf import settings
from rest_framework import serializers
from .models import (Annonce, Cours, CampusApp, Notification, Etablissement,
                     Niveau, Filiere, HeroImage, Resultat, Examen, SessionExamen,
                     Transaction, Paiement, CalendrierAcademique, SiteWeb,
                      AppBranding, OnboardingSlide, AssistantIA, Employe, BulletinPaie,
                      PaiementScolarite, MessageLog, ThemeConfig)

class EtablissementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Etablissement
        fields = '__all__'

class NiveauSerializer(serializers.ModelSerializer):
    class Meta:
        model = Niveau
        fields = '__all__'

class FiliereSerializer(serializers.ModelSerializer):
    class Meta:
        model = Filiere
        fields = '__all__'

class AnnonceSerializer(serializers.ModelSerializer):
    image_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Annonce
        fields = '__all__'

    def get_image_display(self, obj):
        image_url = obj.get_image_url
        if not image_url:
            return None
            
        if image_url.startswith('http'):
            return image_url.replace('http://', 'https://') if 'alwaysdata.net' in image_url else image_url
            
        request = self.context.get('request')
        if request:
            url = request.build_absolute_uri(image_url)
            # Forcer HTTPS pour AlwaysData
            if 'alwaysdata.net' in url:
                url = url.replace('http://', 'https://')
            return url
            
        # Fallback si pas de request
        return f"https://estim-campus.alwaysdata.net{image_url}"

class CoursSerializer(serializers.ModelSerializer):
    # Lecture (GET) : garde les noms en clair pour ne pas casser l'app Flutter
    etablissement = serializers.StringRelatedField(read_only=True)
    niveau = serializers.StringRelatedField(read_only=True)
    filiere = serializers.StringRelatedField(read_only=True)
    enseignant = serializers.StringRelatedField(read_only=True)
    # Écriture (POST/PUT/PATCH) via l'API : passe les IDs
    etablissement_id = serializers.PrimaryKeyRelatedField(
        queryset=Etablissement.objects.all(), source='etablissement', write_only=True
    )
    niveau_id = serializers.PrimaryKeyRelatedField(
        queryset=Niveau.objects.all(), source='niveau', write_only=True
    )
    filiere_id = serializers.PrimaryKeyRelatedField(
        queryset=Filiere.objects.all(), source='filiere', write_only=True
    )
    enseignant_id = serializers.PrimaryKeyRelatedField(
        queryset=Employe.objects.all(), source='enseignant', write_only=True,
        required=False, allow_null=True,
    )
    # Compat : l'app Flutter ne lit que day + les noms ; jours = [1,3,5]
    day_of_week = serializers.IntegerField(read_only=True)

    class Meta:
        model = Cours
        fields = '__all__'

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        ret['jours'] = instance.get_jours_list()
        return ret

    def to_internal_value(self, data):
        data = dict(data) if isinstance(data, dict) else data
        try:
            if isinstance(data, dict) and isinstance(data.get('jours'), list):
                data['jours'] = ",".join(
                    str(int(x)) for x in data['jours'] if str(x).isdigit()
                ) or "1"
            elif isinstance(data, dict) and 'jours' not in data and 'day_of_week' in data:
                data['jours'] = str(int(data['day_of_week']))
        except (ValueError, TypeError):
            pass
        return super().to_internal_value(data)

class CampusAppSerializer(serializers.ModelSerializer):
    class Meta:
        model = CampusApp
        fields = '__all__'

class SessionExamenSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionExamen
        fields = "__all__"


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = "__all__"


class PaiementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Paiement
        fields = "__all__"


class ResultatSerializer(serializers.ModelSerializer):
    session_nom = serializers.CharField(source="session.nom", read_only=True)

    class Meta:
        model = Resultat
        fields = "__all__"

class HeroImageSerializer(serializers.ModelSerializer):
    image_display = serializers.SerializerMethodField()
    class Meta:
        model = HeroImage
        fields = '__all__'
    def get_image_display(self, obj):
        image_url = obj.get_image_url
        if not image_url:
            return None
            
        if image_url.startswith('http'):
            return image_url.replace('http://', 'https://') if 'alwaysdata.net' in image_url else image_url
            
        request = self.context.get('request')
        if request:
            url = request.build_absolute_uri(image_url)
            if 'alwaysdata.net' in url:
                url = url.replace('http://', 'https://')
            return url
            
        return f"https://estim-campus.alwaysdata.net{image_url}"

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'

class ExamenSerializer(serializers.ModelSerializer):
    etablissement = serializers.StringRelatedField(read_only=True)
    niveau = serializers.StringRelatedField(read_only=True)
    filiere = serializers.StringRelatedField(read_only=True)
    etablissement_id = serializers.PrimaryKeyRelatedField(
        queryset=Etablissement.objects.all(), source='etablissement', write_only=True
    )
    niveau_id = serializers.PrimaryKeyRelatedField(
        queryset=Niveau.objects.all(), source='niveau', write_only=True
    )
    filiere_id = serializers.PrimaryKeyRelatedField(
        queryset=Filiere.objects.all(), source='filiere', write_only=True
    )

    class Meta:
        model = Examen
        fields = '__all__'


class CalendrierAcademiqueSerializer(serializers.ModelSerializer):
    class Meta:
        model = CalendrierAcademique
        fields = '__all__'


class SiteWebSerializer(serializers.ModelSerializer):
    class Meta:
        model = SiteWeb
        fields = '__all__'


def _absolute_media_url(obj_url, request):
    """Même logique que HeroImage/Annonce : URL absolue HTTPS pour l'app."""
    if not obj_url:
        return None
    if obj_url.startswith('http'):
        return obj_url.replace('http://', 'https://') if 'alwaysdata.net' in obj_url else obj_url
    if request:
        url = request.build_absolute_uri(obj_url)
        if 'alwaysdata.net' in url:
            url = url.replace('http://', 'https://')
        return url
    return f"https://estim-campus.alwaysdata.net{obj_url}"


class AppBrandingSerializer(serializers.ModelSerializer):
    logo_display = serializers.SerializerMethodField()

    class Meta:
        model = AppBranding
        fields = '__all__'

    def get_logo_display(self, obj):
        return _absolute_media_url(obj.get_logo_url, self.context.get('request'))


class OnboardingSlideSerializer(serializers.ModelSerializer):
    image_display = serializers.SerializerMethodField()

    class Meta:
        model = OnboardingSlide
        fields = '__all__'

    def get_image_display(self, obj):
        return _absolute_media_url(obj.get_image_url, self.context.get('request'))


class AssistantIASerializer(serializers.ModelSerializer):
    class Meta:
        model = AssistantIA
        fields = '__all__'


class EmployeSerializer(serializers.ModelSerializer):
    etablissement = serializers.StringRelatedField(read_only=True)
    filiere = serializers.StringRelatedField(read_only=True)
    etablissement_id = serializers.PrimaryKeyRelatedField(
        queryset=Etablissement.objects.all(), source='etablissement', write_only=True,
        required=False, allow_null=True,
    )
    filiere_id = serializers.PrimaryKeyRelatedField(
        queryset=Filiere.objects.all(), source='filiere', write_only=True,
        required=False, allow_null=True,
    )

    class Meta:
        model = Employe
        fields = '__all__'


class BulletinPaieSerializer(serializers.ModelSerializer):
    employe_display = serializers.StringRelatedField(source='employe', read_only=True)
    net_a_payer = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = BulletinPaie
        fields = '__all__'


class PaiementScolariteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaiementScolarite
        fields = '__all__'
        read_only_fields = ('reference', 'sms_envoye', 'created_at')


class MessageLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MessageLog
        fields = '__all__'


class ThemeConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = ThemeConfig
        fields = ('id', 'name', 'primary_color', 'accent_color', 'is_active', 'updated_at')
