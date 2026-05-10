from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('advances', '0004_advance_authorization_data'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('companies', '0011_company_subscription_fee_credited_at'),
    ]

    operations = [
        migrations.CreateModel(
            name='PlatformCapitalMovement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('movement_type', models.CharField(choices=[('entry', 'Entrada'), ('exit', 'Salida')], max_length=10)),
                ('concept', models.CharField(max_length=180)),
                ('amount', models.DecimalField(decimal_places=2, max_digits=14)),
                ('balance_after', models.DecimalField(decimal_places=2, max_digits=14)),
                ('metadata', models.JSONField(blank=True, default=dict)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('actor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='capital_movements', to=settings.AUTH_USER_MODEL)),
                ('advance', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='capital_movements', to='advances.advance')),
                ('company', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='capital_movements', to='companies.company')),
            ],
            options={
                'verbose_name': 'Movimiento de capital',
                'verbose_name_plural': 'Movimientos de capital',
                'ordering': ['-created_at', '-id'],
            },
        ),
    ]
