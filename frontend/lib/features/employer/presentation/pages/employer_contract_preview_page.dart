import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_popup.dart';
import '../../../companies/data/models/company_model.dart';

class EmployerContractPreviewPage extends StatefulWidget {
  final CompanyModel company;
  final TextEditingController legalNameController;
  final TextEditingController representativeNameController;
  final TextEditingController representativeIdController;
  final TextEditingController contractDurationController;

  const EmployerContractPreviewPage({
    super.key,
    required this.company,
    required this.legalNameController,
    required this.representativeNameController,
    required this.representativeIdController,
    required this.contractDurationController,
  });

  @override
  State<EmployerContractPreviewPage> createState() =>
      _EmployerContractPreviewPageState();
}

class _EmployerContractPreviewPageState
    extends State<EmployerContractPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _actionIcon(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contrato completo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _actionIcon(
                    icon: Icons.download_rounded,
                    onPressed: _downloadContract,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _buildContractDocument(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDocument() {
    final empresa = widget.legalNameController.text;
    final nit = widget.company.taxId ?? '[NIT]';
    final ciudad = widget.company.city ?? '[CIUDAD]';
    final representativeName =
        widget.representativeNameController.text.isNotEmpty
        ? widget.representativeNameController.text
        : '[NOMBRE DEL REPRESENTANTE LEGAL]';
    final representativeId = widget.representativeIdController.text.isNotEmpty
        ? widget.representativeIdController.text
        : '[CEDULA]';
    final duration = widget.contractDurationController.text.isNotEmpty
        ? widget.contractDurationController.text
        : '12 meses';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTRATO DE VINCULACION EMPRESARIAL Y PRESTACION DE SERVICIOS TECNOLOGICOS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'APPDELANTA - Adelantos de nomina y facilitacion de liquidez',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              _bodySpan('Entre '),
              _emphasisSpan(
                'Rafael Ricardo Vanegas Suarez, C.C. No. 1.045.673.206, domiciliado en Barranquilla, Colombia',
              ),
              _bodySpan(
                ', actuando como persona natural comerciante y representante de ',
              ),
              _emphasisSpan('APPDELANTA, LA PLATAFORMA'),
              _bodySpan(';\ny '),
              _emphasisSpan(empresa),
              _bodySpan(
                ', identificada con NIT No. $nit, con domicilio principal en $ciudad,\nrepresentada legalmente por ',
              ),
              _emphasisSpan(representativeName),
              _bodySpan(', C.C. No. $representativeId, '),
              _emphasisSpan('LA EMPRESA'),
              _bodySpan(
                ';\nacuerdan celebrar el presente contrato, regido por las siguientes clausulas:\n',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _contractClause(
          'PRIMERA. OBJETO',
          'Prestacion de servicios tecnologicos para gestion de adelantos de nomina, liquidez, empleados, cupos y solicitudes.',
        ),
        _contractClause(
          'SEGUNDA. FUNCIONAMIENTO DEL SERVICIO',
          'Empleado solicita, empresa aprueba, plataforma gestiona desembolso y empresa descuenta en nomina.',
        ),
        _contractClause(
          'TERCERA. NATURALEZA DEL SERVICIO',
          'APPDELANTA es proveedor tecnologico y facilitador operativo, no entidad financiera ni empleador.',
        ),
        _contractClause(
          'CUARTA. RESPONSABILIDAD DE LA EMPRESA',
          'LA EMPRESA responde por informacion, aprobaciones y pago de valores desembolsados aprobados.',
        ),
        _contractClause(
          'QUINTA. AUTORIZACION DE EMPLEADOS',
          'LA EMPRESA declara contar con autorizaciones para tratamiento de datos y descuentos de nomina.',
        ),
        _contractClause(
          'SEXTA. CUPO EMPRESARIAL Y CUPO POR EMPLEADO',
          'Cupos asignados por validacion, historial, capacidad de pago y condiciones pactadas.',
        ),
        _contractClause(
          'SEPTIMA. TARIFAS, FEE E INTERESES',
          'Fees e intereses segun Anexo 1. Tasa mensual general 2,50%.',
        ),
        _contractClause(
          'OCTAVA. FORMA DE PAGO',
          'LA EMPRESA transferira valores descontados a la cuenta informada por LA PLATAFORMA.',
        ),
        _contractClause(
          'NOVENA. MORA O INCUMPLIMIENTO',
          'La mora permite suspender acceso, bloquear solicitudes, restringir cupos y gestionar cobro.',
        ),
        _contractClause(
          'DECIMA. RETIRO O DESVINCULACION DEL EMPLEADO',
          'La empresa mantiene responsabilidad sobre valores previamente aprobados y desembolsados.',
        ),
        _contractClause(
          'DECIMA PRIMERA. LINEA PRO EMPRESARIAL',
          'Soluciones adicionales sujetas a aprobacion, cupos y condiciones.',
        ),
        _contractClause(
          'DECIMA SEGUNDA. CONFIDENCIALIDAD',
          'Las partes guardaran confidencialidad de informacion comercial, financiera, laboral y tecnica.',
        ),
        _contractClause(
          'DECIMA TERCERA. PROTECCION DE DATOS PERSONALES',
          'Cumplimiento de normativa colombiana de proteccion de datos personales.',
        ),
        _contractClause('DECIMA CUARTA. DURACION', 'Duracion de $duration.'),
        _contractClause(
          'DECIMA QUINTA. TERMINACION',
          'Por mutuo acuerdo, incumplimiento, mora, uso indebido o decision unilateral comunicada.',
        ),
        _contractClause(
          'DECIMA SEXTA. LIMITACION DE RESPONSABILIDAD',
          'Responsabilidad de LA PLATAFORMA limitada al servicio tecnologico.',
        ),
        _contractClause(
          'DECIMA SEPTIMA. CESION',
          'LA PLATAFORMA podra ceder el contrato a una estructura juridica futura relacionada.',
        ),
        _contractClause(
          'DECIMA OCTAVA. LEY APLICABLE',
          'Republica de Colombia.',
        ),
        const SizedBox(height: 20),
        const Text(
          'FIRMAS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _signatureCard(
          title: 'LA PLATAFORMA / APPDELANTA',
          rows: const [
            ('Representante', 'Rafael Ricardo Vanegas Suarez'),
            ('Documento', 'C.C. 1.045.673.206'),
            ('Firma', '____________________________________________'),
          ],
          accent: const Color(0xFFDBEAFE),
        ),
        const SizedBox(height: 12),
        _signatureCard(
          title: 'LA EMPRESA',
          rows: [
            ('Razon social', empresa),
            ('NIT', nit),
            ('Representante legal', representativeName),
            ('Identificacion', representativeId),
            ('Domicilio', ciudad),
            ('Firma', '____________________________________________'),
          ],
          accent: const Color(0xFFE0F2FE),
        ),
        const SizedBox(height: 20),
        const Text(
          'ANEXO 1. TARIFAS, FEES E INTERES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _tableCard(
          headers: const ['Rango', 'Fee', 'Interes'],
          rows: const [
            [r'$50.000 - $150.000', r'$5.000 COP', '2,50% mensual'],
            [r'$150.001 - $400.000', r'$10.000 COP', '2,50% mensual'],
            [r'$400.001 - $1.000.000', r'$15.000 COP', '2,50% mensual'],
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'ANEXOS OPERATIVOS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _annex2CuposCard(),
        const SizedBox(height: 10),
        _annex3DisbursementsCard(),
        const SizedBox(height: 10),
        _annex4DeclaracionCard(),
      ],
    );
  }

  Widget _contractClause(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatureCard({
    required String title,
    required List<(String, String)> rows,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCard({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: headers
                  .map(
                    (header) => Expanded(
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...rows.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row
                    .map(
                      (cell) => Expanded(
                        child: Text(
                          cell,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _annex2CuposCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANEXO 2. CUPOS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          // Tabla de cupos
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _cuposTableRow('Concepto', 'Valor', isHeader: true),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _cuposTableRow('Cupo empresa', r'$10.000.000 COP'),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _cuposTableRow('Maximo por empleado', '50% del salario'),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _cuposTableRow('Dias habiles', '1 a 30 de cada mes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuposTableRow(
    String concepto,
    String valor, {
    bool isHeader = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF0F172A) : Colors.transparent,
        borderRadius: isHeader
            ? const BorderRadius.vertical(top: Radius.circular(11))
            : highlight
            ? const BorderRadius.vertical(bottom: Radius.circular(11))
            : BorderRadius.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            concepto,
            style: TextStyle(
              fontSize: isHeader ? 12 : 13,
              fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
              color: isHeader
                  ? const Color(0xFF64748B)
                  : highlight
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF334155),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: isHeader ? 12 : 13,
              fontWeight: isHeader || highlight
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: isHeader
                  ? const Color(0xFF64748B)
                  : highlight
                  ? Colors.white
                  : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _annex3DisbursementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANEXO 3. DESEMBOLSOS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          // Tabla de horarios
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _tableRow(
                  'Horario solicitud',
                  'Hora desembolso',
                  isHeader: true,
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _tableRow('06:00 - 12:00', '13:00'),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _tableRow('12:01 - 17:00', '18:00'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cuenta de pago destacada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUENTA DE PAGO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '54267607446',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ahorros Bancolombia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Rafael Ricardo Vanegas Suarez',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(String col1, String col2, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              col1,
              style: TextStyle(
                fontSize: isHeader ? 12 : 13,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
                color: isHeader
                    ? const Color(0xFF64748B)
                    : const Color(0xFF334155),
              ),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              style: TextStyle(
                fontSize: isHeader ? 12 : 13,
                fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
                color: isHeader
                    ? const Color(0xFF64748B)
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _annex4DeclaracionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANEXO 4. DECLARACION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'LA EMPRESA declara bajo juramento que:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _declaracionItem(
                  '1.',
                  'Autoriza la verificación de datos para vinculación y habilitación en el sistema.',
                ),
                const SizedBox(height: 8),
                _declaracionItem(
                  '2.',
                  'La información proporcionada es veraz y puede ser validada por AppDelanta.',
                ),
                const SizedBox(height: 8),
                _declaracionItem(
                  '3.',
                  'Conoce y acepta los términos establecidos en el contrato principal.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta declaración tiene carácter de documento público para todos los efectos legales.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _declaracionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _annexCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _bodySpan(String text) => TextSpan(
    text: text,
    style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
  );

  TextSpan _emphasisSpan(String text) => TextSpan(
    text: text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      color: Color(0xFF0F172A),
      height: 1.6,
    ),
  );

  Future<void> _downloadContract() async {
    try {
      final asset = await rootBundle.load(
        'assets/contrato/Contrato_AppDelanta_Vinculacion_Empresarial_Completo.pdf',
      );
      final bytes = asset.buffer.asUint8List();
      final fileName =
          'contrato_appdelanta_${widget.company.name.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_")}.pdf';

      final path = await FilePicker.saveFile(
        dialogTitle: 'Guardar contrato AppDelanta',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (!mounted || path == null) return;

      await AppPopup.show(
        context,
        title: 'Contrato descargado',
        message:
            'Se descargo la version formal del contrato. Diligencialo y firmalo antes de adjuntarlo en la pantalla principal.',
        type: AppPopupType.success,
      );
    } catch (_) {
      if (mounted) {
        await AppPopup.show(
          context,
          title: 'No se pudo descargar',
          message: 'Intenta nuevamente en unos segundos.',
          type: AppPopupType.error,
        );
      }
    }
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
    );
  }
}
