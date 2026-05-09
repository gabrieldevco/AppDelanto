from django.db import migrations, models
from django.utils import timezone


def mark_existing_verified_companies(apps, schema_editor):
    Company = apps.get_model('companies', 'Company')
    Company.objects.filter(
        is_verified=True,
        subscription_fee_credited_at__isnull=True,
    ).update(subscription_fee_credited_at=timezone.now())


class Migration(migrations.Migration):

    dependencies = [
        ('companies', '0010_platform_settings_initial_capital_and_subscription_receipt'),
    ]

    operations = [
        migrations.AddField(
            model_name='company',
            name='subscription_fee_credited_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.RunPython(
            mark_existing_verified_companies,
            reverse_code=migrations.RunPython.noop,
        ),
    ]
