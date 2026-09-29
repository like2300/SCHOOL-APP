from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inscription', '0008_formconfig_colors'),
    ]

    operations = [
        migrations.AddField(
            model_name='inscription',
            name='matricule',
            field=models.CharField(blank=True, help_text='Généré automatiquement à la validation : NOMÉCOLE + 6 chiffres (ex : ESTIM482913).', max_length=20, null=True, unique=True, verbose_name='Matricule étudiant (auto)'),
        ),
    ]
