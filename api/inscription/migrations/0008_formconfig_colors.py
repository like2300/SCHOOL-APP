from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inscription', '0007_inscription_statut'),
    ]

    operations = [
        migrations.AddField(
            model_name='formconfig',
            name='accent_color',
            field=models.CharField(default='#f5a623', max_length=7, verbose_name="Couleur d'accent (badges, progression)"),
        ),
        migrations.AddField(
            model_name='formconfig',
            name='primary_color',
            field=models.CharField(default='#1a6b3c', max_length=7, verbose_name='Couleur principale (boutons, étapes)'),
        ),
        migrations.AddField(
            model_name='formconfig',
            name='primary_dark',
            field=models.CharField(default='#0d4a28', max_length=7, verbose_name='Couleur principale foncée (dégradé)'),
        ),
    ]
