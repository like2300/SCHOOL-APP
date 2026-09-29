from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inscription', '0010_merge_0009'),
    ]

    operations = [
        migrations.AddField(
            model_name='formconfig',
            name='school_short_name',
            field=models.CharField(default='ESTIM', max_length=50, verbose_name="Nom court de l'école (labels du formulaire)"),
        ),
    ]
