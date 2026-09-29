import json

from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver


class Etablissement(models.Model):
    nom = models.CharField(max_length=200, unique=True)
    adresse = models.TextField(
        null=True, blank=True, verbose_name="Adresse de l'établissement"
    )
    agrement = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        verbose_name="Agrément de l'établissement",
    )
    image = models.ImageField(
        upload_to="etablissements/",
        null=True,
        blank=True,
        verbose_name="Image / logo de l'établissement",
    )

    class Meta:
        verbose_name = "Établissement"
        verbose_name_plural = "Établissements"

    def __str__(self):
        return self.nom


class Niveau(models.Model):
    nom = models.CharField(max_length=50, unique=True)

    class Meta:
        verbose_name = "Niveau"
        verbose_name_plural = "Niveaux"

    def __str__(self):
        return self.nom


class Filiere(models.Model):
    nom = models.CharField(max_length=200, unique=True)
    montant_scolarite = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        verbose_name="Montant scolarité (FCFA)",
    )

    class Meta:
        verbose_name = "Filière"
        verbose_name_plural = "Filières"

    def __str__(self):
        return self.nom


class TarifScolarite(models.Model):
    """Tarif par couple Filière + Niveau (prioritaire sur les montants simples)."""

    filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE, verbose_name="Filière")
    niveau = models.ForeignKey(Niveau, on_delete=models.CASCADE, verbose_name="Niveau")
    montant = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Montant (FCFA)")

    class Meta:
        verbose_name = "Tarif scolarité (Filière + Niveau)"
        verbose_name_plural = "Tarifs scolarité (Filière + Niveau)"
        unique_together = ("filiere", "niveau")

    def __str__(self):
        return f"{self.filiere} + {self.niveau} : {self.montant} FCFA"


class Annonce(models.Model):
    TYPE_CHOICES = [
        ("Tous", "Tous"),
        ("Événements", "Événements"),
        ("Cours", "Cours"),
        ("Examens", "Examens"),
        ("Divers", "Divers"),
    ]
    title = models.CharField(max_length=200)
    description = models.TextField()
    date = models.DateTimeField(auto_now_add=True)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES, default="Divers")
    image_url = models.URLField(max_length=500, null=True, blank=True)
    image = models.ImageField(upload_to="annonces/", null=True, blank=True)

    class Meta:
        verbose_name = "Annonce"
        verbose_name_plural = "Annonces"

    @property
    def get_image_url(self):
        if self.image:
            return self.image.url
        return self.image_url

    def __str__(self):
        return self.title


class Cours(models.Model):
    DAY_CHOICES = [
        (i, name)
        for i, name in enumerate(
            [
                "",
                "Lundi",
                "Mardi",
                "Mercredi",
                "Jeudi",
                "Vendredi",
                "Samedi",
                "Dimanche",
            ]
        )
        if i > 0
    ]
    matiere = models.CharField(max_length=200)
    prof = models.CharField(max_length=200)
    salle = models.CharField(max_length=100)
    etablissement = models.ForeignKey(Etablissement, on_delete=models.CASCADE)
    niveau = models.ForeignKey(Niveau, on_delete=models.CASCADE)
    filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE)
    jours = models.CharField(
        max_length=13, default="1",
        verbose_name="Jours de la semaine",
        help_text="Plusieurs jours séparés par des virgules, ex : 1,3,5 (1=Lundi … 7=Dimanche)",
    )
    heure = models.CharField(max_length=50)
    enseignant = models.ForeignKey(
        "Employe", on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="Enseignant assigné",
    )

    class Meta:
        verbose_name = "Cours"
        verbose_name_plural = "Cours"

    def get_jours_list(self):
        """Liste des jours (ints 1-7), ex : [1, 3, 5]."""
        out = []
        for x in str(self.jours or "").split(","):
            x = x.strip()
            if x.isdigit() and 1 <= int(x) <= 7 and int(x) not in out:
                out.append(int(x))
        return out or [1]

    def get_jours_display(self):
        names = dict(self.DAY_CHOICES)
        return ", ".join(names.get(j, "") for j in self.get_jours_list())

    @property
    def jours_badges(self):
        """Les 7 jours alignés (Lun→Dim) avec état sélectionné — 1 ligne par cours, sans doublon."""
        names = dict(self.DAY_CHOICES)
        selected = set(self.get_jours_list())
        return [
            {"num": i, "nom": names.get(i, ""), "init": names.get(i, "")[:1], "on": i in selected}
            for i in range(1, 8)
        ]

    @property
    def day_of_week(self):
        """Compatibilité (ancien champ jour unique) : premier jour."""
        return self.get_jours_list()[0]

    def __str__(self):
        return f"{self.matiere} - {self.niveau}"


class CampusApp(models.Model):
    title = models.CharField(max_length=100)
    description = models.CharField(max_length=255)
    icon_name = models.CharField(max_length=100)
    image_url = models.URLField(max_length=500)
    route = models.CharField(max_length=100, null=True, blank=True)

    class Meta:
        verbose_name = "Application campus"
        verbose_name_plural = "Applications campus"

    def __str__(self):
        return self.title


class HeroImage(models.Model):
    title = models.CharField(max_length=100, blank=True)
    image_url = models.URLField(max_length=500, null=True, blank=True)
    image = models.ImageField(upload_to="hero/", null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Image d'accueil"
        verbose_name_plural = "Images d'accueil"

    @property
    def get_image_url(self):
        if self.image:
            return self.image.url
        return self.image_url

    def __str__(self):
        return self.title or f"Hero {self.id}"


class Notification(models.Model):
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    annonce = models.ForeignKey(
        Annonce, on_delete=models.CASCADE, null=True, blank=True
    )

    # Ajout pour différencier le type de notification
    notification_type = models.CharField(
        max_length=50, default="general"
    )  # 'annonce', 'cours'
    related_id = models.IntegerField(
        null=True, blank=True
    )  # ID de l'annonce ou du cours
    target_matricule = models.CharField(
        max_length=50, null=True, blank=True, verbose_name="Matricule cible"
    )
    # Scope fiche : une notif de cours/examen ne part qu'aux étudiants
    # de l'établissement (et optionnellement niveau/filière).
    etablissement = models.ForeignKey(
        Etablissement, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="Établissement cible",
    )
    niveau = models.ForeignKey(
        Niveau, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="Niveau cible",
    )
    filiere = models.ForeignKey(
        Filiere, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="Filière cible",
    )

    class Meta:
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"

    def __str__(self):
        return self.title


class SessionExamen(models.Model):
    nom = models.CharField(max_length=200, unique=True)
    is_active = models.BooleanField(default=True)
    results_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Session d'examen"
        verbose_name_plural = "Sessions d'examen"

    def __str__(self):
        return self.nom


class Resultat(models.Model):
    session = models.ForeignKey(
        SessionExamen, on_delete=models.CASCADE, related_name="resultats", null=True
    )
    matricule = models.CharField(max_length=50)
    nom_etudiant = models.CharField(max_length=200)
    moyenne = models.DecimalField(max_digits=4, decimal_places=2)
    admis = models.BooleanField(default=False)
    details_notes = models.JSONField(default=dict)  # {"Maths": 15, "Physique": 12}
    sms_envoye = models.BooleanField(default=False, verbose_name="SMS résultat envoyé")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("matricule", "session")
        verbose_name = "Résultat"
        verbose_name_plural = "Résultats"

    def __str__(self):
        return f"{self.nom_etudiant} ({self.matricule}) - {self.session.nom if self.session else 'No Session'}"


class Transaction(models.Model):
    STATUS_CHOICES = [
        ("PENDING", "En attente"),
        ("SUCCESS", "Réussi"),
        ("FAILED", "Échoué"),
    ]
    payer_matricule = models.CharField(max_length=50)
    target_matricule = models.CharField(max_length=50)
    session = models.ForeignKey(
        SessionExamen, on_delete=models.CASCADE, null=True, blank=True
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_ref = models.CharField(max_length=100, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="PENDING")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"

    def __str__(self):
        return f"{self.payer_matricule} -> {self.target_matricule} ({self.status})"


class Paiement(models.Model):
    payer_matricule = models.CharField(max_length=50, verbose_name="Matricule Payeur")
    target_matricule = models.CharField(max_length=50, verbose_name="Matricule Cible")
    session = models.ForeignKey(
        SessionExamen,
        on_delete=models.CASCADE,
        verbose_name="Session",
        null=True,
        blank=True,
    )
    reference = models.CharField(
        max_length=100, unique=True, verbose_name="Référence Paiement"
    )
    amount = models.DecimalField(
        max_digits=10, decimal_places=2, verbose_name="Montant"
    )
    payment_method = models.CharField(
        max_length=50, null=True, blank=True, verbose_name="Méthode de Paiement"
    )
    created_at = models.DateTimeField(
        auto_now_add=True, verbose_name="Date de Paiement"
    )

    class Meta:
        verbose_name = "Paiement Réussi"
        verbose_name_plural = "Paiements Réussis"

    def __str__(self):
        return f"{self.payer_matricule} payé pour {self.target_matricule} - {self.reference}"


class Examen(models.Model):
    TYPE_CHOICES = [
        ("Examen", "Examen"),
        ("Devoir", "Devoir"),
        ("Rattrapage", "Rattrapage"),
        ("Session", "Session"),
        ("Autres", "Autres"),
    ]
    matiere = models.CharField(max_length=200)
    date = models.DateField()
    heure = models.TimeField()
    salle = models.CharField(max_length=100)
    etablissement = models.ForeignKey(Etablissement, on_delete=models.CASCADE)
    niveau = models.ForeignKey(Niveau, on_delete=models.CASCADE)
    filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES, default="Examen")

    class Meta:
        verbose_name = "Examen"
        verbose_name_plural = "Examens"

    def __str__(self):
        return f"{self.type} - {self.matiere} ({self.date})"


class CalendrierAcademique(models.Model):
    title = models.CharField(max_length=200, verbose_name="Titre de l'événement")
    description = models.TextField(verbose_name="Description", blank=True)
    date_debut = models.DateField(verbose_name="Date de début")
    date_fin = models.DateField(verbose_name="Date de fin", null=True, blank=True)
    is_important = models.BooleanField(default=False, verbose_name="Important")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Calendrier Académique"
        verbose_name_plural = "Calendrier Académique"
        ordering = ["date_debut"]

    def __str__(self):
        return f"{self.title} ({self.date_debut})"


class SiteWeb(models.Model):
    title = models.CharField(max_length=100, verbose_name="Nom du site")
    url = models.URLField(max_length=500, verbose_name="URL du site")
    icon_name = models.CharField(
        max_length=50, default="public", verbose_name="Nom de l'icône Material"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Lien Site Web"
        verbose_name_plural = "Liens Sites Web"

    def __str__(self):
        return self.title


class AppBranding(models.Model):
    """Logo + nom de l'app, modifiable depuis /admin/ et exposé à l'app mobile."""

    app_name = models.CharField(max_length=100, default="Estim Campus")
    logo = models.ImageField(
        upload_to="branding/", null=True, blank=True, verbose_name="Logo (upload)"
    )
    logo_url = models.URLField(
        max_length=500, null=True, blank=True, verbose_name="Logo (URL externe)"
    )
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Logo / Branding de l'app"
        verbose_name_plural = "Logo / Branding de l'app"

    @property
    def get_logo_url(self):
        if self.logo:
            return self.logo.url
        return self.logo_url

    def __str__(self):
        return self.app_name


class AssistantIA(models.Model):
    """Nom + personnalité de l'assistant, modifiables depuis /admin/ et exposés à l'app mobile."""

    nom = models.CharField(max_length=100, default="ESTIM AI", verbose_name="Nom de l'assistant")
    personnalite = models.TextField(
        default="Tu es un assistant académique expert. RÈGLE CRITIQUE : Il est STRICTEMENT INTERDIT d'aider à tricher, de donner des réponses directes pendant un examen ou de résoudre des devoirs à la place de l'étudiant. Sois concis, encourage l'apprentissage et adapte ton langage à la filière de l'étudiant.",
        verbose_name="Personnalité (prompt système)",
    )
    is_active = models.BooleanField(default=True, verbose_name="Actif")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Assistant IA"
        verbose_name_plural = "Assistant IA"

    def __str__(self):
        return self.nom


class OnboardingSlide(models.Model):
    """Images + textes de l'onboarding (starter.dart), changeables depuis /admin/."""

    title = models.CharField(max_length=100, verbose_name="Titre")
    description = models.TextField(verbose_name="Description")
    image = models.ImageField(
        upload_to="onboarding/", null=True, blank=True, verbose_name="Image (upload)"
    )
    image_url = models.URLField(
        max_length=500, null=True, blank=True, verbose_name="Image (URL externe)"
    )
    ordre = models.PositiveIntegerField(default=0, verbose_name="Ordre d'affichage")
    is_active = models.BooleanField(default=True, verbose_name="Actif")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Slide d'onboarding"
        verbose_name_plural = "Slides d'onboarding"
        ordering = ["ordre", "created_at"]

    @property
    def get_image_url(self):
        if self.image:
            return self.image.url
        return self.image_url

    def __str__(self):
        return f"{self.ordre} - {self.title}"


MOIS_CHOICES = [
    (1, "Janvier"), (2, "Février"), (3, "Mars"), (4, "Avril"),
    (5, "Mai"), (6, "Juin"), (7, "Juillet"), (8, "Août"),
    (9, "Septembre"), (10, "Octobre"), (11, "Novembre"), (12, "Décembre"),
]


class AnneeAcademique(models.Model):
    """Année académique : période exploitée pour le suivi des dettes scolarité."""

    nom = models.CharField(max_length=20, unique=True, default="2025-2026", verbose_name="Année (ex : 2025-2026)")
    mois_debut = models.PositiveSmallIntegerField(choices=MOIS_CHOICES, default=10, verbose_name="Mois début des cours")
    mois_fin = models.PositiveSmallIntegerField(choices=MOIS_CHOICES, default=6, verbose_name="Mois fin des cours")
    is_active = models.BooleanField(default=True, verbose_name="Année en cours")

    class Meta:
        verbose_name = "Année académique"
        verbose_name_plural = "Années académiques"
        ordering = ["-nom"]

    def __str__(self):
        return self.nom


class ThemeConfig(models.Model):
    """Couleur du panneau admin, modifiable depuis /admin/ (onglet Configuration)."""

    name = models.CharField(max_length=100, default="Thème principal")
    primary_color = models.CharField(
        max_length=7, default="#7c3aed", verbose_name="Couleur principale (hex, ex : #1a6b3c)"
    )
    accent_color = models.CharField(
        max_length=7, default="#f5a623", verbose_name="Couleur d'accent (hex, ex : #f5a623)"
    )
    is_active = models.BooleanField(default=True, verbose_name="Actif")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Thème de l'admin"
        verbose_name_plural = "Thèmes de l'admin"

    def __str__(self):
        return f"{self.name} ({self.primary_color})"


class Employe(models.Model):
    """Personnel de l'université : enseignants + administratifs, avec documents et salaire."""

    TYPE_CHOICES = [
        ("ENSEIGNANT", "Enseignant"),
        ("ADMINISTRATIF", "Administratif"),
    ]
    STATUT_CHOICES = [
        ("ACTIF", "Actif"),
        ("INACTIF", "Inactif"),
        ("SUSPENDU", "Suspendu"),
    ]

    type_personnel = models.CharField(max_length=15, choices=TYPE_CHOICES, default="ENSEIGNANT", verbose_name="Type de personnel")
    last_name = models.CharField(max_length=255, verbose_name="Nom(s)")
    first_name = models.CharField(max_length=255, verbose_name="Prénom(s)")
    sexe = models.CharField(max_length=1, choices=[("M", "Masculin"), ("F", "Féminin")], default="M")
    phone = models.CharField(max_length=20, verbose_name="Téléphone")
    email = models.EmailField(null=True, blank=True, verbose_name="Email")
    adresse = models.CharField(max_length=255, null=True, blank=True, verbose_name="Adresse")

    fonction = models.CharField(max_length=255, verbose_name="Fonction / Poste")
    etablissement = models.ForeignKey(Etablissement, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Établissement")
    filiere = models.ForeignKey(Filiere, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Filière d'affectation")
    user = models.OneToOneField(
        "auth.User", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="profil_employe", verbose_name="Compte de connexion",
    )

    salaire_base = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Salaire de base (FCFA)")
    date_embauche = models.DateField(null=True, blank=True, verbose_name="Date d'embauche")
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default="ACTIF")

    photo = models.ImageField(upload_to="employes/photos/", null=True, blank=True, verbose_name="Photo")
    cv = models.FileField(upload_to="employes/docs/", null=True, blank=True, verbose_name="CV")
    diplome = models.FileField(upload_to="employes/docs/", null=True, blank=True, verbose_name="Diplôme")
    contrat = models.FileField(upload_to="employes/docs/", null=True, blank=True, verbose_name="Contrat de travail")
    piece_identite = models.FileField(upload_to="employes/docs/", null=True, blank=True, verbose_name="Pièce d'identité")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Employé"
        verbose_name_plural = "Employés"

    def __str__(self):
        return f"{self.last_name} {self.first_name} ({self.get_type_personnel_display()})"


class BulletinPaie(models.Model):
    """Fiche de paie mensuelle d'un employé (imprimable)."""

    employe = models.ForeignKey(Employe, on_delete=models.CASCADE, related_name="bulletins", verbose_name="Employé")
    mois = models.PositiveSmallIntegerField(verbose_name="Mois (1-12)")
    annee = models.PositiveIntegerField(verbose_name="Année")
    salaire_base = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Salaire de base (FCFA)")
    primes = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Primes (FCFA)")
    retenues = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name="Retenues (FCFA)")
    verse_le = models.DateField(null=True, blank=True, verbose_name="Versé le")
    observation = models.TextField(blank=True, verbose_name="Observation")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Bulletin de paie"
        verbose_name_plural = "Bulletins de paie"
        unique_together = ("employe", "mois", "annee")
        ordering = ["-annee", "-mois"]

    @property
    def net_a_payer(self):
        return (self.salaire_base or 0) + (self.primes or 0) - (self.retenues or 0)

    def save(self, *args, **kwargs):
        if not self.salaire_base and self.employe_id:
            try:
                self.salaire_base = Employe.objects.get(pk=self.employe_id).salaire_base
            except Employe.DoesNotExist:
                pass
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.employe} — {self.mois:02d}/{self.annee}"


class PaiementScolarite(models.Model):
    """Paiement d'un étudiant enregistré au bureau + ticket imprimable + SMS au tuteur."""

    MOTIF_CHOICES = [
        ("SCOLARITE", "Scolarité"),
        ("INSCRIPTION", "Inscription"),
        ("EXAMEN", "Frais d'examen"),
        ("AUTRE", "Autre"),
    ]
    METHODE_CHOICES = [
        ("ESPECES", "Espèces"),
        ("MOBILE_MONEY", "Mobile Money"),
        ("VIREMENT", "Virement"),
        ("AUTRE", "Autre"),
    ]

    reference = models.CharField(max_length=20, unique=True, null=True, blank=True, verbose_name="Référence du reçu")
    matricule = models.CharField(max_length=50, verbose_name="Matricule étudiant")
    nom_etudiant = models.CharField(max_length=200, verbose_name="Nom de l'étudiant")
    niveau = models.ForeignKey(Niveau, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Niveau")
    filiere = models.ForeignKey(Filiere, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Filière")
    annee_academique = models.ForeignKey(
        AnneeAcademique, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name="Année académique",
    )
    mois = models.PositiveSmallIntegerField(
        choices=MOIS_CHOICES, null=True, blank=True,
        verbose_name="Mois concerné",
        help_text="Mois de scolarité couvert par ce paiement (limité à la période de l'année académique).",
    )
    motif = models.CharField(max_length=15, choices=MOTIF_CHOICES, default="SCOLARITE")
    montant = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Montant (FCFA)")
    methode = models.CharField(max_length=15, choices=METHODE_CHOICES, default="ESPECES", verbose_name="Méthode")
    phone_tuteur = models.CharField(max_length=20, null=True, blank=True, verbose_name="N° tuteur (SMS)")
    recu_par = models.CharField(max_length=255, null=True, blank=True, verbose_name="Reçu par (agent)")
    sms_envoye = models.BooleanField(default=False, verbose_name="SMS envoyé")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date de paiement")

    class Meta:
        verbose_name = "Paiement scolarité"
        verbose_name_plural = "Paiements scolarité"
        ordering = ["-created_at"]

    def clean(self):
        from django.core.exceptions import ValidationError

        super().clean()
        # Règle : on ne paie pas 2 fois le même mois (même motif, même année).
        if self.matricule and self.mois and self.annee_academique_id and self.motif:
            doublon = PaiementScolarite.objects.filter(
                matricule__iexact=self.matricule.strip(),
                annee_academique_id=self.annee_academique_id,
                mois=self.mois,
                motif=self.motif,
            )
            if self.pk:
                doublon = doublon.exclude(pk=self.pk)
            ancien = doublon.first()
            if ancien:
                raise ValidationError({
                    'mois': f"{self.nom_etudiant} a déjà payé ce mois ({ancien.get_mois_display()} — Réf {ancien.reference}, {ancien.montant} FCFA). Choisis un autre mois.",
                })

    def generate_reference(self):
        import random
        import string

        chars = string.ascii_uppercase + string.digits
        while True:
            ref = "REC-" + "".join(random.choice(chars) for _ in range(8))
            if not PaiementScolarite.objects.filter(reference=ref).exists():
                return ref

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = self.generate_reference()
        is_new = self._state.adding
        super().save(*args, **kwargs)
        # Envoi (ou relance) du SMS tant qu'il n'est pas marqué envoyé et
        # qu'un numéro tuteur est renseigné — couvre aussi le cas d'un
        # paiement créé sans numéro puis modifié ensuite.
        if self.phone_tuteur and not self.sms_envoye:
            from .whatsapp import build_recu_message, send_tutor_message

            message = build_recu_message(self)
            if send_tutor_message(self.phone_tuteur, message):
                PaiementScolarite.objects.filter(pk=self.pk).update(sms_envoye=True)
                self.sms_envoye = True

    def __str__(self):
        return f"{self.reference} — {self.nom_etudiant} ({self.montant} FCFA)"


class MessageLog(models.Model):
    """Journal des messages WhatsApp/SMS envoyés (anti-blocage : traçabilité)."""

    STATUS_CHOICES = [
        ("SUCCESS", "Envoyé"),
        ("FAILED", "Échoué"),
        ("SKIPPED", "Ignoré"),
    ]

    to = models.CharField(max_length=20, verbose_name="Destinataire")
    message = models.TextField(verbose_name="Message")
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="FAILED")
    response = models.TextField(null=True, blank=True, verbose_name="Réponse API")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Message WhatsApp"
        verbose_name_plural = "Journal WhatsApp"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.to} — {self.status} ({self.created_at:%d/%m/%Y %H:%M})"


class ProfilEtablissement(models.Model):
    """Lie un compte admin à UNE OU PLUSIEURS écoles (scoping admin)."""

    from django.conf import settings as _settings
    user = models.OneToOneField(
        _settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="profil_etablissement", verbose_name="Compte admin",
    )
    etablissements = models.ManyToManyField(
        Etablissement, blank=True, verbose_name="Écoles gérées",
    )

    class Meta:
        verbose_name = "Admin d'établissement"
        verbose_name_plural = "Admins d'établissement"

    def __str__(self):
        return f"{self.user} → {', '.join(e.nom for e in self.etablissements.all())}"


@receiver(post_save, sender=Annonce)
def create_notification_on_annonce(sender, instance, created, **kwargs):
    if created:
        # Notification générale (sans target_matricule) destinée à tous
        Notification.objects.create(
            title=f"📣 {instance.title}",
            message=instance.description[:200] if instance.description else "",
            notification_type="annonce",
            related_id=instance.id,
            annonce=instance,
        )


@receiver(post_save, sender=Cours)
def create_notification_on_cours(sender, instance, created, **kwargs):
    if created:
        # Liée à la fiche : établissement + niveau + filière du cours.
        Notification.objects.create(
            title=f"📚 Nouveau cours: {instance.matiere}",
            message=f"{instance.matiere} avec {instance.prof} en salle {instance.salle}.",
            notification_type="cours",
            related_id=instance.id,
            etablissement=instance.etablissement,
            niveau=instance.niveau,
            filiere=instance.filiere,
        )


@receiver(post_save, sender=Examen)
def create_notification_on_examen(sender, instance, created, **kwargs):
    if created:
        # Liée à la fiche : établissement + niveau + filière de l'examen.
        Notification.objects.create(
            title=f"📝 {instance.type}: {instance.matiere}",
            message=(
                f"{instance.type} de {instance.matiere} prévu le "
                f"{instance.date} à {instance.heure} en salle {instance.salle}."
            ),
            notification_type="examen",
            related_id=instance.id,
            etablissement=instance.etablissement,
            niveau=instance.niveau,
            filiere=instance.filiere,
        )


@receiver(post_save, sender=Resultat)
def create_notification_on_resultat(sender, instance, created, **kwargs):
    if created:
        # Créer notification UNIQUEMENT si matricule est présent
        if instance.matricule:
            Notification.objects.create(
                title=f"🎓 Nouveau résultat disponible",
                message=f"Félicitations {instance.nom_etudiant}, votre résultat pour la session {instance.session.nom} est disponible !",
                notification_type="resultat",
                related_id=instance.id,
                target_matricule=instance.matricule,
            )
        # SMS/WhatsApp : résultat dispo + lien de l'app (DB) + infos de connexion.
        try:
            if not instance.sms_envoye:
                from .whatsapp import send_tutor_message
                from .resultat_message import build_resultat_message, find_inscription_for_resultat

                inscription = find_inscription_for_resultat(instance)
                if inscription is not None:
                    message = build_resultat_message(instance, inscription)
                    dest = inscription.phone or inscription.tel_tuteur
                    if message and dest and send_tutor_message(dest, message):
                        Resultat.objects.filter(pk=instance.pk).update(sms_envoye=True)
                        instance.sms_envoye = True
        except Exception:
            pass


@receiver(post_save, sender=CalendrierAcademique)
def create_notification_on_calendrier(sender, instance, created, **kwargs):
    if created:
        # Notification générale destinée à tous
        Notification.objects.create(
            title=f"📅 {instance.title}",
            message=(instance.description[:200] if instance.description else ""),
            notification_type="calendrier",
            related_id=instance.id,
        )
