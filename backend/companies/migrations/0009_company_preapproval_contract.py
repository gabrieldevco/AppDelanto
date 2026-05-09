from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('companies', '0008_alter_company_tax_id'),
    ]

    operations = [
        migrations.AddField(
            model_name='company',
            name='city',
            field=models.CharField(blank=True, max_length=120, verbose_name='Ciudad'),
        ),
        migrations.AddField(
            model_name='company',
            name='is_preapproved',
            field=models.BooleanField(default=False, verbose_name='Preaprobada'),
        ),
        migrations.AddField(
            model_name='company',
            name='platform_contract_file',
            field=models.FileField(
                blank=True,
                null=True,
                upload_to='employer_documents/platform_contracts/',
                verbose_name='Contrato firmado con AppDelanta',
            ),
        ),
        migrations.AddField(
            model_name='company',
            name='platform_contract_uploaded_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='company',
            name='platform_contract_verified_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
