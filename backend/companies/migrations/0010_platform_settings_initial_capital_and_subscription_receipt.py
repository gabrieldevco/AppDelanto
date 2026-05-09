from django.db import migrations, models


def seed_initial_capital(apps, schema_editor):
    PlatformSettings = apps.get_model('companies', 'PlatformSettings')
    settings, _ = PlatformSettings.objects.get_or_create(pk=1)
    if not settings.initial_capital:
        settings.initial_capital = 20000000
        settings.save(update_fields=['initial_capital'])


class Migration(migrations.Migration):

    dependencies = [
        ('companies', '0009_company_preapproval_contract'),
    ]

    operations = [
        migrations.AddField(
            model_name='company',
            name='subscription_receipt_file',
            field=models.FileField(
                blank=True,
                null=True,
                upload_to='employer_documents/subscription_receipts/',
                verbose_name='Volante de suscripcion',
            ),
        ),
        migrations.AddField(
            model_name='company',
            name='subscription_receipt_uploaded_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='platformsettings',
            name='initial_capital',
            field=models.DecimalField(decimal_places=2, default=20000000, max_digits=14),
        ),
        migrations.RunPython(seed_initial_capital, migrations.RunPython.noop),
    ]
