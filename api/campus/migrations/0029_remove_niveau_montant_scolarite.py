from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('campus', '0028_themeconfig_accent_color_profiletablissement'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='niveau',
            name='montant_scolarite',
        ),
    ]
