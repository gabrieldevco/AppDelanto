from django.urls import path
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from users.views import user_management, verify_company


def _decimal_str(value):
    return str(value or 0)


def _interest_expression():
    from django.db.models import DecimalField, ExpressionWrapper, F
    return ExpressionWrapper(
        F('total_amount') - F('amount') - F('fee'),
        output_field=DecimalField(max_digits=12, decimal_places=2),
    )


def _recovered_profit_expression():
    from django.db.models import DecimalField, ExpressionWrapper, F
    return ExpressionWrapper(
        F('total_amount') - F('amount'),
        output_field=DecimalField(max_digits=12, decimal_places=2),
    )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard(request):
    """Obtener estadísticas del dashboard para admin"""
    from decimal import Decimal
    from django.db.models import DecimalField, ExpressionWrapper, F, Sum
    from django.utils import timezone
    from users.models import User
    from companies.models import Company
    from advances.models import Advance
    from notifications.models import Notification
    
    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=403)
    
    # Estadísticas de usuarios
    total_users = User.objects.count()
    employees = User.objects.filter(role='employee').count()
    employers = User.objects.filter(role='employer').count()
    
    # Estadísticas de empresas
    total_companies = Company.objects.count()
    verified_companies = Company.objects.filter(is_verified=True).count()
    
    # Estadísticas de adelantos
    total_advances = Advance.objects.count()
    pending_advances = Advance.objects.filter(status='pending').count()
    approved_advances = Advance.objects.filter(status='approved').count()
    disbursed_advances = Advance.objects.filter(status='disbursed').count()
    
    # Montos reales de adelantos y ganancias de plataforma
    completed_advances = Advance.objects.filter(status__in=['disbursed', 'recovered'])
    total_disbursed = completed_advances.aggregate(
        total=Sum('amount')
    )['total'] or 0
    recovered_profit_expression = _recovered_profit_expression()
    total_recovered = Advance.objects.filter(status='recovered').annotate(
        recovered_profit=recovered_profit_expression
    ).aggregate(total=Sum('recovered_profit'))['total'] or 0
    total_fees = completed_advances.aggregate(
        total=Sum('fee')
    )['total'] or 0
    interest_expression = ExpressionWrapper(
        F('total_amount') - F('amount') - F('fee'),
        output_field=DecimalField(max_digits=12, decimal_places=2),
    )
    total_interest = completed_advances.annotate(
        calculated_interest=interest_expression
    ).aggregate(total=Sum('calculated_interest'))['total'] or 0
    total_earnings = total_fees + total_interest
    
    # Suscripciones: 50000 por cada empresa verificada
    SUBSCRIPTION_AMOUNT = Decimal('50000')
    total_subscriptions = SUBSCRIPTION_AMOUNT * verified_companies
    
    # Total incluyendo suscripciones
    total_earnings_with_subscriptions = total_earnings + total_subscriptions

    month_labels = {
        1: 'Ene', 2: 'Feb', 3: 'Mar', 4: 'Abr',
        5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Ago',
        9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dic',
    }

    def add_months(date, months):
        month = date.month - 1 + months
        year = date.year + month // 12
        month = month % 12 + 1
        return date.replace(year=year, month=month, day=1)

    current_month = timezone.now().date().replace(day=1)
    monthly = []
    for offset in range(-3, 1):
        month_start = add_months(current_month, offset)
        next_month = add_months(month_start, 1)
        month_advances = Advance.objects.filter(
            request_date__date__gte=month_start,
            request_date__date__lt=next_month,
        )
        month_disbursed = month_advances.filter(
            status__in=['disbursed', 'recovered']
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        month_recovered = month_advances.filter(status='recovered').annotate(
            recovered_profit=recovered_profit_expression
        ).aggregate(total=Sum('recovered_profit'))['total'] or Decimal('0')
        monthly.append({
            'label': month_labels[month_start.month],
            'disbursed': str(month_disbursed),
            'recovered': str(month_recovered),
        })
    
    # Notificaciones recientes
    recent_notifications = Notification.objects.order_by('-created_at')[:5]
    
    return Response({
        'users': {
            'total': total_users,
            'employees': employees,
            'employers': employers,
        },
        'companies': {
            'total': total_companies,
            'verified': verified_companies,
            'pending': total_companies - verified_companies,
        },
        'advances': {
            'total': total_advances,
            'pending': pending_advances,
            'approved': approved_advances,
            'disbursed': disbursed_advances,
            'recovered': Advance.objects.filter(status='recovered').count(),
            'total_disbursed': str(total_disbursed),
            'total_recovered': str(total_recovered),
        },
        'earnings': {
            'total': str(total_earnings_with_subscriptions),
            'fees': str(total_fees),
            'interest': str(total_interest),
            'subscriptions': str(total_subscriptions),
            'verified_companies_count': verified_companies,
        },
        'monthly': monthly,
        'recent_notifications': [
            {
                'id': n.id,
                'title': n.title,
                'message': n.message,
                'type': n.type,
                'created_at': n.created_at,
            }
            for n in recent_notifications
        ],
    })


def _serialize_platform_settings():
    from companies.models import DisbursementWindow, FeeRange, PlatformSettings

    settings = PlatformSettings.get_solo()
    FeeRange.ensure_defaults()
    DisbursementWindow.ensure_defaults()
    fee_ranges = FeeRange.objects.all()
    windows = DisbursementWindow.objects.all()

    return {
        'interest_rate_monthly': _decimal_str(settings.interest_rate_monthly),
        'max_salary_percentage': _decimal_str(settings.max_salary_percentage),
        'initial_capital': _decimal_str(settings.initial_capital),
        'min_days': settings.min_days,
        'max_days': settings.max_days,
        'min_amount': _decimal_str(fee_ranges.order_by('min_amount').first().min_amount),
        'max_amount': _decimal_str(fee_ranges.order_by('-max_amount').first().max_amount),
        'fee_ranges': [
            {
                'id': item.id,
                'min_amount': _decimal_str(item.min_amount),
                'max_amount': _decimal_str(item.max_amount),
                'fee': _decimal_str(item.fee),
                'order': item.order,
            }
            for item in fee_ranges
        ],
        'disbursement_windows': [
            {
                'id': item.id,
                'name': item.name,
                'start_time': item.start_time.strftime('%H:%M'),
                'end_time': item.end_time.strftime('%H:%M'),
                'processing_time': item.processing_time.strftime('%H:%M'),
                'order': item.order,
            }
            for item in windows
        ],
    }


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def platform_settings(request):
    from decimal import Decimal
    from django.db.models import Sum
    from companies.models import Company, CompanySettings, DisbursementWindow, FeeRange, PlatformSettings
    from users.models import EmployeeProfile

    if request.method == 'GET':
        return Response(_serialize_platform_settings())

    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=403)

    settings = PlatformSettings.get_solo()
    data = request.data
    old_capital = settings.initial_capital
    settings.interest_rate_monthly = Decimal(str(data.get('interest_rate_monthly', settings.interest_rate_monthly)))
    settings.max_salary_percentage = Decimal(str(data.get('max_salary_percentage', settings.max_salary_percentage)))
    settings.initial_capital = Decimal(str(data.get('initial_capital', settings.initial_capital)))
    settings.min_days = int(data.get('min_days', settings.min_days))
    settings.max_days = int(data.get('max_days', settings.max_days))
    settings.save()

    if settings.initial_capital != old_capital:
        from companies.models import PlatformCapitalMovement

        difference = settings.initial_capital - old_capital
        PlatformCapitalMovement.record(
            movement_type='entry' if difference > 0 else 'exit',
            concept='Ajuste manual de capital',
            amount=abs(difference),
            balance_after=settings.initial_capital,
            actor=request.user,
            metadata={'source': 'settings_update'},
        )

    fee_ranges = data.get('fee_ranges')
    if isinstance(fee_ranges, list) and fee_ranges:
        FeeRange.objects.all().delete()
        for index, item in enumerate(fee_ranges, start=1):
            FeeRange.objects.create(
                min_amount=Decimal(str(item.get('min_amount', 0))),
                max_amount=Decimal(str(item.get('max_amount', 0))),
                fee=Decimal(str(item.get('fee', 0))),
                order=int(item.get('order', index)),
            )

    windows = data.get('disbursement_windows')
    if isinstance(windows, list) and windows:
        DisbursementWindow.objects.all().delete()
        for index, item in enumerate(windows, start=1):
            DisbursementWindow.objects.create(
                name=item.get('name') or f'Franja {index}',
                start_time=item.get('start_time') or '06:00',
                end_time=item.get('end_time') or '12:00',
                processing_time=item.get('processing_time') or '13:00',
                order=int(item.get('order', index)),
            )

    FeeRange.ensure_defaults()
    min_amount = FeeRange.objects.order_by('min_amount').first().min_amount
    max_amount = FeeRange.objects.order_by('-max_amount').first().max_amount
    CompanySettings.objects.update(min_advance_amount=min_amount, max_advance_amount=max_amount)
    Company.objects.update(max_advance_percentage=settings.max_salary_percentage)

    for profile in EmployeeProfile.objects.all():
        disbursed_total = profile.advances.filter(status='disbursed').aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0')
        profile.available_advance_limit = (
            profile.salary * settings.max_salary_percentage / Decimal('100')
        ) - disbursed_total
        if profile.available_advance_limit < 0:
            profile.available_advance_limit = Decimal('0')
        profile.save(update_fields=['available_advance_limit'])

    return Response(_serialize_platform_settings())


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def platform_capital_movement(request):
    from decimal import Decimal, InvalidOperation
    from django.db import transaction
    from companies.models import PlatformCapitalMovement, PlatformSettings

    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=403)

    action = (request.data.get('action') or '').strip().lower()
    if action not in ('deposit', 'withdraw', 'entry', 'exit'):
        return Response({'error': 'Accion invalida'}, status=400)

    try:
        amount = Decimal(str(request.data.get('amount', '0')))
    except (InvalidOperation, TypeError, ValueError):
        return Response({'error': 'El monto no es valido'}, status=400)

    if amount <= 0:
        return Response({'error': 'El monto debe ser mayor que cero'}, status=400)

    is_entry = action in ('deposit', 'entry')
    concept = request.data.get('concept') or (
        'Ingreso manual de fondos' if is_entry else 'Retiro manual de fondos'
    )

    with transaction.atomic():
        settings = PlatformSettings.objects.select_for_update().get(
            pk=PlatformSettings.get_solo().pk
        )
        if not is_entry and settings.initial_capital < amount:
            return Response({'error': 'Capital insuficiente para retirar fondos'}, status=400)

        if is_entry:
            settings.initial_capital += amount
        else:
            settings.initial_capital -= amount
        settings.save(update_fields=['initial_capital', 'updated_at'])

        movement = PlatformCapitalMovement.record(
            movement_type='entry' if is_entry else 'exit',
            concept=concept,
            amount=amount,
            balance_after=settings.initial_capital,
            actor=request.user,
            metadata={'source': 'manual_capital_movement'},
        )

    data = _serialize_platform_settings()
    data['movement'] = {
        'id': movement.id,
        'movement_type': movement.movement_type,
        'concept': movement.concept,
        'amount': _decimal_str(movement.amount),
        'balance_after': _decimal_str(movement.balance_after),
        'created_at': movement.created_at,
    }
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def reports(request):
    from datetime import timedelta
    from decimal import Decimal
    from django.db.models import Sum
    from django.utils import timezone
    from users.models import EmployeeProfile, User
    from companies.models import Company, PlatformCapitalMovement
    from advances.models import Advance

    if not request.user.is_admin:
        return Response({'error': 'No autorizado'}, status=403)

    end_date = request.query_params.get('end_date') or timezone.now().date().isoformat()
    start_date = request.query_params.get('start_date')
    if not start_date:
        start_date = (timezone.now().date() - timedelta(days=30)).isoformat()
    employer_id = request.query_params.get('employer_id')

    advances = Advance.objects.filter(
        request_date__date__gte=start_date,
        request_date__date__lte=end_date,
    )
    if employer_id:
        advances = advances.filter(company_id=employer_id)

    completed = advances.filter(status__in=['disbursed', 'recovered'])
    recovered = advances.filter(status='recovered')
    rejected = advances.filter(status='rejected')
    approved = advances.filter(status__in=['approved', 'disbursed', 'recovered'])
    interest_expr = _interest_expression()
    recovered_profit_expr = _recovered_profit_expression()
    subscription_amount = Decimal('50000')
    movements = PlatformCapitalMovement.objects.select_related(
        'actor', 'company', 'advance__employee__user',
    ).filter(
        created_at__date__gte=start_date,
        created_at__date__lte=end_date,
    )
    if employer_id:
        movements = movements.filter(company_id=employer_id)
    subscription_movements = movements.filter(
        movement_type='entry',
        concept='Suscripcion de empresa',
    )
    subscription_companies = Company.objects.filter(is_verified=True)
    if employer_id:
        subscription_companies = subscription_companies.filter(id=employer_id)

    total_disbursed = completed.aggregate(total=Sum('amount'))['total'] or 0
    total_recovered = recovered.annotate(
        recovered_profit=recovered_profit_expr
    ).aggregate(total=Sum('recovered_profit'))['total'] or 0
    total_fees = completed.aggregate(total=Sum('fee'))['total'] or 0
    total_interest = completed.annotate(calculated_interest=interest_expr).aggregate(
        total=Sum('calculated_interest')
    )['total'] or 0
    total_subscriptions = subscription_movements.aggregate(total=Sum('amount'))['total']
    if total_subscriptions is None:
        total_subscriptions = subscription_amount * subscription_companies.count()

    employers = Company.objects.all().order_by('name')
    breakdown = []
    for company in employers:
        company_advances = advances.filter(company=company)
        company_completed = company_advances.filter(status__in=['disbursed', 'recovered'])
        company_recovered = company_advances.filter(status='recovered')
        company_fees = company_completed.aggregate(total=Sum('fee'))['total'] or 0
        company_interest = company_completed.annotate(calculated_interest=interest_expr).aggregate(
            total=Sum('calculated_interest')
        )['total'] or 0
        company_subscriptions = subscription_movements.filter(company=company).aggregate(
            total=Sum('amount')
        )['total']
        if company_subscriptions is None:
            company_subscriptions = (
                subscription_amount
                if subscription_companies.filter(id=company.id).exists()
                else Decimal('0')
            )
        breakdown.append({
            'id': company.id,
            'name': company.name,
            'employer_name': company.admin.get_full_name() or company.admin.email,
            'employer_document': company.admin.document_number,
            'employees': company.employee_count,
            'requests': company_advances.count(),
            'disbursed': _decimal_str(company_completed.aggregate(total=Sum('amount'))['total']),
            'recovered': _decimal_str(
                company_recovered.annotate(
                    recovered_profit=recovered_profit_expr
                ).aggregate(total=Sum('recovered_profit'))['total']
            ),
            'earnings': _decimal_str(company_fees + company_interest + company_subscriptions),
            'fees': _decimal_str(company_fees),
            'interest': _decimal_str(company_interest),
            'subscriptions': _decimal_str(company_subscriptions),
        })

    employee_profiles = EmployeeProfile.objects.select_related('user', 'company').filter(
        company__isnull=False,
    ).order_by('company__name', 'user__first_name', 'user__last_name', 'user__email')
    if employer_id:
        employee_profiles = employee_profiles.filter(company_id=employer_id)

    employee_details = []
    for profile in employee_profiles:
        employee_advances = advances.filter(
            employee=profile,
            status__in=['disbursed', 'recovered'],
        )
        employee_details.append({
            'id': profile.id,
            'name': profile.user.get_full_name() or profile.user.email,
            'document': profile.user.document_number,
            'company': profile.company.name if profile.company_id else '',
            'salary': _decimal_str(profile.salary),
            'advanced': _decimal_str(employee_advances.aggregate(total=Sum('amount'))['total']),
        })

    extracts = []
    for movement in movements:
        employee_name = ''
        if movement.advance_id and movement.advance.employee_id:
            employee_name = movement.advance.employee.user.get_full_name() or movement.advance.employee.user.email
        actor_name = ''
        if movement.actor_id:
            actor_name = movement.actor.get_full_name() or movement.actor.email
        extracts.append({
            'sort_at': movement.created_at,
            'date': movement.created_at,
            'type': 'Movimiento de capital',
            'movement_type': movement.movement_type,
            'direction': 'Entrada' if movement.movement_type == 'entry' else 'Salida',
            'concept': movement.concept,
            'company': movement.company.name if movement.company_id else '',
            'employee': employee_name,
            'actor': actor_name,
            'amount': _decimal_str(movement.amount),
            'balance_after': _decimal_str(movement.balance_after),
            'fee': _decimal_str(movement.metadata.get('fee', 0)),
            'interest': _decimal_str(movement.metadata.get('interest', 0)),
        })

    registered_companies = Company.objects.filter(
        created_at__date__gte=start_date,
        created_at__date__lte=end_date,
    )
    if employer_id:
        registered_companies = registered_companies.filter(id=employer_id)
    for company in registered_companies:
        extracts.append({
            'sort_at': company.created_at,
            'date': company.created_at,
            'type': 'Empresa registrada',
            'movement_type': 'info',
            'direction': 'Registro',
            'concept': 'Empresa registrada',
            'company': company.name,
            'employee': '',
            'actor': company.admin.get_full_name() or company.admin.email,
            'amount': '0',
            'balance_after': '',
            'fee': '0',
            'interest': '0',
        })

    employees = EmployeeProfile.objects.select_related('user', 'company').filter(
        user__created_at__date__gte=start_date,
        user__created_at__date__lte=end_date,
        company__isnull=False,
    )
    if employer_id:
        employees = employees.filter(company_id=employer_id)
    for profile in employees:
        extracts.append({
            'sort_at': profile.user.created_at,
            'date': profile.user.created_at,
            'type': 'Empleado registrado',
            'movement_type': 'info',
            'direction': 'Registro',
            'concept': 'Empleado registrado',
            'company': profile.company.name if profile.company_id else '',
            'employee': profile.user.get_full_name() or profile.user.email,
            'actor': '',
            'amount': '0',
            'balance_after': '',
            'fee': '0',
            'interest': '0',
        })

    extracts.sort(key=lambda item: item['sort_at'], reverse=True)
    for item in extracts:
        item.pop('sort_at', None)

    return Response({
        'filters': {
            'start_date': start_date,
            'end_date': end_date,
            'employer_id': int(employer_id) if employer_id else None,
        },
        'employers': [{'id': item.id, 'name': item.name} for item in employers],
        'summary': {
            'disbursed': _decimal_str(total_disbursed),
            'recovered': _decimal_str(total_recovered),
            'earnings': _decimal_str(total_fees + total_interest + total_subscriptions),
            'fees': _decimal_str(total_fees),
            'interest': _decimal_str(total_interest),
            'subscriptions': _decimal_str(total_subscriptions),
        },
        'processed': {
            'total': approved.count() + rejected.count(),
            'approved': approved.count(),
            'rejected': rejected.count(),
        },
        'breakdown': breakdown,
        'employees_detail': employee_details,
        'extracts': extracts,
        'totals': {
            'active_employers': Company.objects.filter(is_active=True).count(),
            'employees': User.objects.filter(role='employee').count(),
        },
    })

urlpatterns = [
    path('dashboard/', dashboard, name='dashboard'),
    path('reports/', reports, name='reports'),
    path('settings/capital-movement/', platform_capital_movement, name='platform-capital-movement'),
    path('settings/', platform_settings, name='platform-settings'),
    path('user-management/', user_management, name='user-management'),
    path('verify-company/<int:company_id>/', verify_company, name='verify-company'),
]
