import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_popup.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_notifications_drawer.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  int? _employerId;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  Future<void> _loadReports() {
    return context.read<AdminProvider>().loadReports(
      startDate: _apiDate(_startDate),
      endDate: _apiDate(_endDate),
      employerId: _employerId,
    );
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _uiDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  int _toInt(dynamic value) => _toDouble(value).round();

  String _currency(dynamic value) {
    final amount = _toDouble(value).round();
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '\$ $formatted';
  }

  String _dateTime(dynamic value) {
    final parsed = DateTime.tryParse('${value ?? ''}');
    if (parsed == null) return '${value ?? ''}';
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _signedCurrency(Map item) {
    final amount = _currency(item['amount']);
    if (item['movement_type'] == 'exit') return '-$amount';
    if (item['movement_type'] == 'entry') return '+$amount';
    return amount;
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    await _loadReports();
  }

  Future<void> _exportExcel() async {
    final report = context.read<AdminProvider>().reports;
    if (report == null || report.isEmpty) {
      await _showExportMessage(
        'Excel',
        success: false,
        detail: 'No hay datos para exportar',
      );
      return;
    }

    final fileName =
        'reporte_appdelanta_${_apiDate(_startDate)}_${_apiDate(_endDate)}.xls';
    final bytes = Uint8List.fromList(utf8.encode(_buildExcelHtml(report)));
    await _saveReportFile(
      bytes: bytes,
      fileName: fileName,
      type: 'Excel',
      allowedExtensions: const ['xls'],
    );
  }

  Future<void> _exportPdf() async {
    final report = context.read<AdminProvider>().reports;
    if (report == null || report.isEmpty) {
      await _showExportMessage(
        'PDF',
        success: false,
        detail: 'No hay datos para exportar',
      );
      return;
    }

    final fileName =
        'reporte_appdelanta_${_apiDate(_startDate)}_${_apiDate(_endDate)}.pdf';
    final bytes = _buildPdfBytes(report);
    await _saveReportFile(
      bytes: bytes,
      fileName: fileName,
      type: 'PDF',
      allowedExtensions: const ['pdf'],
    );
  }

  Future<void> _saveReportFile({
    required Uint8List bytes,
    required String fileName,
    required String type,
    required List<String> allowedExtensions,
  }) async {
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Guardar reporte $type',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        bytes: bytes,
      );

      if (!mounted) return;
      if (path == null) {
        await _showExportMessage(
          type,
          success: false,
          detail: 'Guardado cancelado',
        );
        return;
      }

      await _showExportMessage(type);
    } catch (e) {
      if (!mounted) return;
      await _showExportMessage(
        type,
        success: false,
        detail: 'No se pudo guardar: $e',
      );
    }
  }

  Future<void> _showExportMessage(
    String type, {
    bool success = true,
    String? detail,
  }) {
    return AppPopup.show(
      context,
      title: success ? 'Reporte $type generado' : 'No se pudo generar',
      message: detail ?? 'El archivo fue generado con los filtros actuales.',
      type: success ? AppPopupType.success : AppPopupType.error,
    );
  }

  String _plain(dynamic value) {
    return '${value ?? ''}'
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _buildExcelHtml(Map<String, dynamic> report) {
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final processed = report['processed'] as Map<String, dynamic>? ?? {};
    final totals = report['totals'] as Map<String, dynamic>? ?? {};
    final breakdown = report['breakdown'] as List? ?? const [];
    final employeesDetail = report['employees_detail'] as List? ?? const [];
    final extracts = report['extracts'] as List? ?? const [];

    final rows = StringBuffer()
      ..writeln('<tr><th colspan="2">Resumen del periodo</th></tr>')
      ..writeln(
        '<tr><td>Fecha inicio</td><td>${_apiDate(_startDate)}</td></tr>',
      )
      ..writeln('<tr><td>Fecha fin</td><td>${_apiDate(_endDate)}</td></tr>')
      ..writeln(
        '<tr><td>Desembolsado</td><td>${_currency(summary['disbursed'])}</td></tr>',
      )
      ..writeln(
        '<tr><td>Recuperado</td><td>${_currency(summary['recovered'])}</td></tr>',
      )
      ..writeln(
        '<tr><td>Ganancias</td><td>${_currency(summary['earnings'])}</td></tr>',
      )
      ..writeln('<tr><td>Fees</td><td>${_currency(summary['fees'])}</td></tr>')
      ..writeln(
        '<tr><td>Intereses</td><td>${_currency(summary['interest'])}</td></tr>',
      )
      ..writeln(
        '<tr><td>Suscripciones</td><td>${_currency(summary['subscriptions'])}</td></tr>',
      )
      ..writeln('<tr><th colspan="2">Solicitudes</th></tr>')
      ..writeln('<tr><td>Total</td><td>${_toInt(processed['total'])}</td></tr>')
      ..writeln(
        '<tr><td>Aprobadas</td><td>${_toInt(processed['approved'])}</td></tr>',
      )
      ..writeln(
        '<tr><td>Rechazadas</td><td>${_toInt(processed['rejected'])}</td></tr>',
      )
      ..writeln('<tr><th colspan="2">Totales</th></tr>')
      ..writeln(
        '<tr><td>Empleadores activos</td><td>${_toInt(totals['active_employers'])}</td></tr>',
      )
      ..writeln(
        '<tr><td>Empleados registrados</td><td>${_toInt(totals['employees'])}</td></tr>',
      );

    final employerRows = StringBuffer();
    for (final item in breakdown) {
      final employer = item as Map;
      employerRows.writeln(
        '<tr><td>${_plain(employer['name'])}</td>'
        '<td>${_plain(employer['employer_name'])}</td>'
        '<td>${_plain(employer['employer_document'])}</td>'
        '<td>${_toInt(employer['employees'])}</td>'
        '<td>${_toInt(employer['requests'])}</td>'
        '<td>${_currency(employer['disbursed'])}</td>'
        '<td>${_currency(employer['recovered'])}</td>'
        '<td>${_currency(employer['fees'])}</td>'
        '<td>${_currency(employer['interest'])}</td>'
        '<td>${_currency(employer['subscriptions'])}</td>'
        '<td>${_currency(employer['earnings'])}</td></tr>',
      );
    }

    final employeeRows = StringBuffer();
    for (final item in employeesDetail) {
      final employee = item as Map;
      employeeRows.writeln(
        '<tr>'
        '<td>${_plain(employee['name'])}</td>'
        '<td>${_plain(employee['document'])}</td>'
        '<td>${_plain(employee['company'])}</td>'
        '<td>${_currency(employee['salary'])}</td>'
        '<td>${_currency(employee['advanced'])}</td>'
        '</tr>',
      );
    }

    final extractRows = StringBuffer();
    for (final item in extracts) {
      final extract = item as Map;
      extractRows.writeln(
        '<tr>'
        '<td>${_plain(_dateTime(extract['date']))}</td>'
        '<td>${_plain(extract['direction'])}</td>'
        '<td>${_plain(extract['concept'])}</td>'
        '<td>${_plain(extract['company'])}</td>'
        '<td>${_plain(extract['employee'])}</td>'
        '<td>${_plain(extract['actor'])}</td>'
        '<td>${_plain(_signedCurrency(extract))}</td>'
        '<td>${_plain(extract['fee'])}</td>'
        '<td>${_plain(extract['interest'])}</td>'
        '<td>${_plain(extract['balance_after'])}</td>'
        '</tr>',
      );
    }

    return '''
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; color: #111827; }
    h1 { color: #4F46E5; }
    table { border-collapse: collapse; width: 100%; margin-bottom: 24px; }
    th { background: #F3E8FF; color: #4F46E5; text-align: left; }
    th, td { border: 1px solid #E5E7EB; padding: 8px; }
  </style>
</head>
<body>
  <h1>Reporte Appdelanta</h1>
  <table>$rows</table>
  <h2>Desglose por empleador</h2>
  <table>
    <tr>
      <th>Empleador</th><th>Usuario empleador</th><th>CC empleador</th>
      <th>Empleados</th><th>Solicitudes</th>
      <th>Desembolsado</th><th>Recuperado</th><th>Fees</th>
      <th>Intereses</th><th>Suscripciones</th><th>Ganancias</th>
    </tr>
    $employerRows
  </table>
  <h2>Empleados</h2>
  <table>
    <tr>
      <th>Empleado</th><th>CC</th><th>Empresa</th><th>Salario</th><th>Adelantado</th>
    </tr>
    $employeeRows
  </table>
  <h2>Extractos</h2>
  <table>
    <tr>
      <th>Fecha</th><th>Tipo</th><th>Concepto</th><th>Empresa</th>
      <th>Empleado</th><th>Administrador</th><th>Monto</th>
      <th>Fee</th><th>Interes</th><th>Saldo</th>
    </tr>
    $extractRows
  </table>
</body>
</html>
''';
  }

  Uint8List _buildPdfBytes(Map<String, dynamic> report) {
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final processed = report['processed'] as Map<String, dynamic>? ?? {};
    final totals = report['totals'] as Map<String, dynamic>? ?? {};
    final breakdown = report['breakdown'] as List? ?? const [];
    final employeesDetail = report['employees_detail'] as List? ?? const [];
    final extracts = report['extracts'] as List? ?? const [];

    final content = StringBuffer();

    void fillRect(double x, double y, double width, double height, String rgb) {
      content.writeln('q $rgb rg $x $y $width $height re f Q');
    }

    void strokeRect(
      double x,
      double y,
      double width,
      double height,
      String rgb,
    ) {
      content.writeln('q $rgb RG 0.8 w $x $y $width $height re S Q');
    }

    void text(
      String value,
      double x,
      double y, {
      double size = 10,
      String font = 'F1',
      String rgb = '0.07 0.09 0.15',
    }) {
      content.writeln(
        'BT $rgb rg /$font $size Tf $x $y Td (${_pdfEscape(value)}) Tj ET',
      );
    }

    void metricCard(
      double x,
      double y,
      double width,
      String label,
      String value,
      String fill,
      String accent,
    ) {
      fillRect(x, y, width, 58, fill);
      strokeRect(x, y, width, 58, '0.88 0.90 0.94');
      text(label, x + 14, y + 36, size: 9, rgb: '0.39 0.45 0.55');
      text(value, x + 14, y + 16, size: 15, font: 'F2', rgb: accent);
    }

    fillRect(0, 0, 612, 792, '0.98 0.98 1');
    fillRect(36, 704, 540, 58, '0.31 0.18 0.81');
    fillRect(36, 690, 540, 14, '0.49 0.22 0.86');
    text('Reporte Appdelanta', 56, 736, size: 22, font: 'F2', rgb: '1 1 1');
    text(
      'Periodo: ${_apiDate(_startDate)} - ${_apiDate(_endDate)}',
      56,
      718,
      size: 10,
      rgb: '0.88 0.84 1',
    );
    text(
      'Generado con filtros actuales',
      410,
      718,
      size: 9,
      rgb: '0.88 0.84 1',
    );

    text('Resumen del periodo', 40, 666, size: 15, font: 'F2');
    metricCard(
      40,
      590,
      160,
      'Desembolsado',
      _currency(summary['disbursed']),
      '0.93 0.98 0.96',
      '0.05 0.59 0.53',
    );
    metricCard(
      226,
      590,
      160,
      'Recuperado',
      _currency(summary['recovered']),
      '0.96 0.95 1',
      '0.31 0.27 0.90',
    );
    metricCard(
      412,
      590,
      160,
      'Ganancias',
      _currency(summary['earnings']),
      '0.99 0.95 1',
      '0.49 0.18 0.80',
    );

    text('Detalle financiero', 40, 552, size: 13, font: 'F2');
    fillRect(40, 480, 160, 54, '1 1 1');
    strokeRect(40, 480, 160, 54, '0.88 0.90 0.94');
    text('Fees', 56, 512, size: 10, rgb: '0.39 0.45 0.55');
    text(
      _currency(summary['fees']),
      56,
      492,
      size: 14,
      font: 'F2',
      rgb: '0.31 0.27 0.90',
    );
    fillRect(226, 480, 160, 54, '1 1 1');
    strokeRect(226, 480, 160, 54, '0.88 0.90 0.94');
    text('Intereses', 242, 512, size: 10, rgb: '0.39 0.45 0.55');
    text(
      _currency(summary['interest']),
      242,
      492,
      size: 14,
      font: 'F2',
      rgb: '0.86 0.15 0.15',
    );
    fillRect(412, 480, 160, 54, '1 1 1');
    strokeRect(412, 480, 160, 54, '0.88 0.90 0.94');
    text('Suscripciones', 428, 512, size: 10, rgb: '0.39 0.45 0.55');
    text(
      _currency(summary['subscriptions']),
      428,
      492,
      size: 14,
      font: 'F2',
      rgb: '0.05 0.59 0.53',
    );

    text('Solicitudes y cobertura', 40, 442, size: 13, font: 'F2');
    metricCard(
      40,
      366,
      120,
      'Total solicitudes',
      '${_toInt(processed['total'])}',
      '0.96 0.95 1',
      '0.31 0.27 0.90',
    );
    metricCard(
      178,
      366,
      120,
      'Aprobadas',
      '${_toInt(processed['approved'])}',
      '0.93 0.98 0.96',
      '0.05 0.59 0.53',
    );
    metricCard(
      316,
      366,
      120,
      'Rechazadas',
      '${_toInt(processed['rejected'])}',
      '1 0.95 0.95',
      '0.86 0.15 0.15',
    );
    metricCard(
      454,
      366,
      118,
      'Empleados',
      '${_toInt(totals['employees'])}',
      '0.96 0.98 1',
      '0.08 0.41 0.76',
    );

    text('Desglose por empleador', 40, 326, size: 13, font: 'F2');
    fillRect(40, 302, 532, 20, '0.95 0.93 1');
    text('Empleador', 48, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Usuario', 168, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('CC', 280, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Emp.', 338, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Desemb.', 384, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Ganancia', 482, 309, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');

    var rowY = 280.0;
    if (breakdown.isEmpty) {
      text(
        'Sin datos para el periodo',
        48,
        rowY,
        size: 10,
        rgb: '0.39 0.45 0.55',
      );
    } else {
      for (final item in breakdown.take(3)) {
        final employer = item as Map;
        final fill = ((302 - rowY) / 22).round().isEven
            ? '1 1 1'
            : '0.98 0.98 1';
        fillRect(40, rowY - 6, 532, 20, fill);
        strokeRect(40, rowY - 6, 532, 20, '0.91 0.93 0.96');
        final name = '${employer['name'] ?? ''}';
        text(
          name.length > 18 ? '${name.substring(0, 18)}...' : name,
          48,
          rowY,
          size: 8.5,
        );
        final employerName = '${employer['employer_name'] ?? ''}';
        text(
          employerName.length > 17
              ? '${employerName.substring(0, 17)}...'
              : employerName,
          168,
          rowY,
          size: 8.5,
        );
        text('${employer['employer_document'] ?? ''}', 280, rowY, size: 8.5);
        text('${_toInt(employer['employees'])}', 342, rowY, size: 8.5);
        text(_currency(employer['disbursed']), 384, rowY, size: 8.5);
        text(_currency(employer['earnings']), 482, rowY, size: 8.5);
        rowY -= 22;
      }
    }

    text('Extractos', 40, 220, size: 13, font: 'F2');
    fillRect(40, 196, 532, 20, '0.95 0.93 1');
    text('Fecha', 48, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Tipo', 118, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Concepto', 178, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Empresa', 330, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Monto', 454, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');
    text('Saldo', 520, 203, size: 8, font: 'F2', rgb: '0.31 0.27 0.90');

    var extractY = 174.0;
    if (extracts.isEmpty) {
      text(
        'Sin extractos para el periodo',
        48,
        extractY,
        size: 9,
        rgb: '0.39 0.45 0.55',
      );
    } else {
      for (final item in extracts.take(4)) {
        final extract = item as Map;
        fillRect(40, extractY - 6, 532, 20, '1 1 1');
        strokeRect(40, extractY - 6, 532, 20, '0.91 0.93 0.96');
        final concept = '${extract['concept'] ?? ''}';
        final company = '${extract['company'] ?? ''}';
        text(
          _dateTime(extract['date']).split(' ').first,
          48,
          extractY,
          size: 7.5,
        );
        text('${extract['direction'] ?? ''}', 118, extractY, size: 7.5);
        text(
          concept.length > 25 ? '${concept.substring(0, 25)}...' : concept,
          178,
          extractY,
          size: 7.5,
        );
        text(
          company.length > 18 ? '${company.substring(0, 18)}...' : company,
          330,
          extractY,
          size: 7.5,
        );
        text(_signedCurrency(extract), 454, extractY, size: 7.5);
        text(_currency(extract['balance_after']), 520, extractY, size: 7.5);
        extractY -= 22;
      }
    }

    fillRect(36, 34, 540, 24, '0.96 0.95 1');
    text(
      'Appdelanta | Reporte administrativo',
      50,
      43,
      size: 9,
      rgb: '0.39 0.45 0.55',
    );

    List<String> tablePages({
      required String title,
      required List<String> headers,
      required List<double> x,
      required List<List<String>> rows,
    }) {
      String trimTo(String value, int max) {
        if (value.length <= max) return value;
        if (max <= 3) return value.substring(0, max);
        return '${value.substring(0, max - 3)}...';
      }

      final pages = <String>[];
      final chunks = rows.isEmpty
          ? <List<List<String>>>[const []]
          : [
              for (var i = 0; i < rows.length; i += 24)
                rows.skip(i).take(24).toList(),
            ];

      for (var pageIndex = 0; pageIndex < chunks.length; pageIndex++) {
        final page = StringBuffer();

        void pFill(
          double left,
          double top,
          double width,
          double height,
          String rgb,
        ) {
          page.writeln('q $rgb rg $left $top $width $height re f Q');
        }

        void pStroke(
          double left,
          double top,
          double width,
          double height,
          String rgb,
        ) {
          page.writeln('q $rgb RG 0.8 w $left $top $width $height re S Q');
        }

        void pText(
          String value,
          double left,
          double top, {
          double size = 8,
          String font = 'F1',
          String rgb = '0.07 0.09 0.15',
        }) {
          page.writeln(
            'BT $rgb rg /$font $size Tf $left $top Td (${_pdfEscape(value)}) Tj ET',
          );
        }

        pFill(0, 0, 612, 792, '0.98 0.98 1');
        pFill(36, 704, 540, 58, '0.31 0.18 0.81');
        pFill(36, 690, 540, 14, '0.49 0.22 0.86');
        pText(title, 56, 736, size: 21, font: 'F2', rgb: '1 1 1');
        pText(
          'Periodo: ${_apiDate(_startDate)} - ${_apiDate(_endDate)}',
          56,
          718,
          size: 10,
          rgb: '0.88 0.84 1',
        );

        pFill(40, 652, 532, 24, '0.95 0.93 1');
        for (var i = 0; i < headers.length; i++) {
          pText(
            headers[i],
            x[i],
            661,
            size: 8,
            font: 'F2',
            rgb: '0.31 0.27 0.90',
          );
        }

        var y = 626.0;
        if (chunks[pageIndex].isEmpty) {
          pText(
            'Sin datos para mostrar',
            48,
            y,
            size: 10,
            rgb: '0.39 0.45 0.55',
          );
        } else {
          for (final row in chunks[pageIndex]) {
            pFill(40, y - 6, 532, 20, '1 1 1');
            pStroke(40, y - 6, 532, 20, '0.91 0.93 0.96');
            for (var i = 0; i < row.length; i++) {
              pText(
                trimTo(row[i], i == 0 || i == 2 ? 22 : 16),
                x[i],
                y,
                size: 7.5,
              );
            }
            y -= 22;
          }
        }

        pFill(36, 34, 540, 24, '0.96 0.95 1');
        pText(
          'Appdelanta | Reporte administrativo | Pagina ${pageIndex + 1}',
          50,
          43,
          size: 9,
          rgb: '0.39 0.45 0.55',
        );
        pages.add(page.toString());
      }
      return pages;
    }

    final employeePdfRows = employeesDetail.map<List<String>>((item) {
      final employee = item as Map;
      return [
        '${employee['name'] ?? ''}',
        '${employee['document'] ?? ''}',
        '${employee['company'] ?? ''}',
        _currency(employee['salary']),
        _currency(employee['advanced']),
      ];
    }).toList();

    final extractPdfRows = extracts.map<List<String>>((item) {
      final extract = item as Map;
      return [
        _dateTime(extract['date']).split(' ').first,
        '${extract['direction'] ?? ''}',
        '${extract['concept'] ?? ''}',
        '${extract['company'] ?? ''}',
        _signedCurrency(extract),
        _currency(extract['balance_after']),
      ];
    }).toList();

    final pageContents = <String>[
      content.toString(),
      ...tablePages(
        title: 'Empleados',
        headers: const ['Empleado', 'CC', 'Empresa', 'Salario', 'Adelantado'],
        x: const [48, 184, 256, 394, 486],
        rows: employeePdfRows,
      ),
      ...tablePages(
        title: 'Extractos',
        headers: const [
          'Fecha',
          'Tipo',
          'Concepto',
          'Empresa',
          'Monto',
          'Saldo',
        ],
        x: const [48, 112, 176, 322, 438, 510],
        rows: extractPdfRows,
      ),
    ];

    final objects = <String>[
      '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n',
      '',
      '3 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n',
      '4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> endobj\n',
    ];
    final pageObjectIds = <int>[];
    var nextObjectId = 5;
    for (final pageContent in pageContents) {
      final pageObjectId = nextObjectId++;
      final contentObjectId = nextObjectId++;
      pageObjectIds.add(pageObjectId);
      objects.add(
        '$pageObjectId 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $contentObjectId 0 R >> endobj\n',
      );
      objects.add(
        '$contentObjectId 0 obj << /Length ${utf8.encode(pageContent).length} >> stream\n$pageContent\nendstream endobj\n',
      );
    }
    objects[1] =
        '2 0 obj << /Type /Pages /Kids [${pageObjectIds.map((id) => '$id 0 R').join(' ')}] /Count ${pageObjectIds.length} >> endobj\n';

    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (final object in objects) {
      offsets.add(utf8.encode(buffer.toString()).length);
      buffer.write(object);
    }
    final xrefOffset = utf8.encode(buffer.toString()).length;
    buffer
      ..writeln('xref')
      ..writeln('0 ${objects.length + 1}')
      ..writeln('0000000000 65535 f ');
    for (final offset in offsets.skip(1)) {
      buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    buffer
      ..writeln('trailer << /Size ${objects.length + 1} /Root 1 0 R >>')
      ..writeln('startxref')
      ..writeln(xrefOffset)
      ..writeln('%%EOF');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _pdfEscape(String value) {
    return value
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      endDrawer: const AdminNotificationsDrawer(),
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final report = adminProvider.reports ?? <String, dynamic>{};
            final summary = report['summary'] as Map<String, dynamic>? ?? {};
            final processed =
                report['processed'] as Map<String, dynamic>? ?? {};
            final totals = report['totals'] as Map<String, dynamic>? ?? {};
            final employers = report['employers'] as List? ?? const [];
            final breakdown = report['breakdown'] as List? ?? const [];
            final employeesDetail =
                report['employees_detail'] as List? ?? const [];
            final extracts = report['extracts'] as List? ?? const [];

            return RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminHeader(currentIndex: 3),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reportes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Analitica y estadisticas detalladas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFilters(employers),
                          const SizedBox(height: 20),
                          if (adminProvider.isLoading && report.isEmpty)
                            const Center(child: CircularProgressIndicator())
                          else if (adminProvider.error != null &&
                              report.isEmpty)
                            _buildError(adminProvider.error!)
                          else ...[
                            _buildPeriodSummary(summary),
                            const SizedBox(height: 20),
                            _buildEarnings(summary),
                            const SizedBox(height: 20),
                            _buildProcessed(processed),
                            const SizedBox(height: 20),
                            _buildBreakdown(breakdown),
                            const SizedBox(height: 20),
                            _buildEmployeesDetail(employeesDetail),
                            const SizedBox(height: 20),
                            _buildExtracts(extracts),
                            const SizedBox(height: 20),
                            _buildTotals(totals),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFilters(List employers) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros de Consulta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  'Fecha inicio',
                  _startDate,
                  () => _pickDate(start: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(
                  'Fecha fin',
                  _endDate,
                  () => _pickDate(start: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Empleador',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int?>(
            initialValue: _employerId,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los empleadores'),
              ),
              ...employers.map(
                (item) => DropdownMenuItem<int?>(
                  value: item['id'] as int,
                  child: Text('${item['name']}'),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() => _employerId = value);
              await _loadReports();
            },
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 20),
          _exportButton(
            'Generar Reporte Excel',
            Icons.table_chart,
            const Color(0xFF0D9488),
            const [Color(0xFF14B8A6), Color(0xFF059669)],
            _exportExcel,
          ),
          const SizedBox(height: 12),
          _exportButton(
            'Generar Reporte PDF',
            Icons.picture_as_pdf,
            const Color(0xFFDC2626),
            const [Color(0xFFFB7185), Color(0xFFDC2626)],
            _exportPdf,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Resumen del Periodo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_apiDate(_startDate)} - ${_apiDate(_endDate)}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  'Desembolsado',
                  _currency(summary['disbursed']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryTile(
                  'Recuperado',
                  _currency(summary['recovered']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnings(Map<String, dynamic> summary) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text(
                'Ganancias de la Plataforma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _earningsRow(
            'Total ganancias',
            _currency(summary['earnings']),
            const Color(0xFF7C3AED),
          ),
          _earningsRow(
            'Fee por transacciones',
            _currency(summary['fees']),
            const Color(0xFF4F46E5),
          ),
          _earningsRow(
            'Intereses',
            _currency(summary['interest']),
            const Color(0xFFDC2626),
          ),
          _earningsRow(
            'Suscripciones',
            _currency(summary['subscriptions']),
            const Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessed(Map<String, dynamic> processed) {
    final total = _toInt(processed['total']);
    final approved = _toInt(processed['approved']);
    final rejected = _toInt(processed['rejected']);
    final approvedPercent = total == 0 ? 0 : (approved / total * 100).round();
    final rejectedPercent = total == 0 ? 0 : (rejected / total * 100).round();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitudes Procesadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Center(
            child: _metricBox(
              'Total solicitudes',
              '$total',
              const Color(0xFFF5F3FF),
              const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  'Aprobadas',
                  '$approved\n$approvedPercent%',
                  const Color(0xFFECFDF5),
                  const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricBox(
                  'Rechazadas',
                  '$rejected\n$rejectedPercent%',
                  const Color(0xFFFEF2F2),
                  const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(List breakdown) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text(
                'Desglose por Empleador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (breakdown.isEmpty)
            const Text(
              'Sin datos para el periodo',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...breakdown.map((item) => _employerCard(item as Map)),
        ],
      ),
    );
  }

  Widget _buildTotals(Map<String, dynamic> totals) {
    return Row(
      children: [
        Expanded(
          child: _totalCard(
            Icons.business_center,
            '${_toInt(totals['active_employers'])}',
            'Empleadores activos',
            const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _totalCard(
            Icons.people,
            '${_toInt(totals['employees'])}',
            'Empleados registrados',
            const Color(0xFF0D9488),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesDetail(List employees) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Empleados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (employees.isEmpty)
            const Text(
              'Sin empleados para mostrar',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...employees.map((item) => _employeeDetailCard(item as Map)),
        ],
      ),
    );
  }

  Widget _employeeDetailCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item['name'] ?? ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            '${item['company'] ?? ''} | CC ${item['document'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Salario',
                  _currency(item['salary']),
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Adelantado',
                  _currency(item['advanced']),
                  const Color(0xFFECFDF5),
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtracts(List extracts) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF0D9488), size: 20),
              SizedBox(width: 8),
              Text(
                'Extractos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (extracts.isEmpty)
            const Text(
              'Sin movimientos para el periodo',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...extracts.take(12).map((item) => _extractCard(item as Map)),
        ],
      ),
    );
  }

  Widget _extractCard(Map item) {
    final isEntry = item['movement_type'] == 'entry';
    final isExit = item['movement_type'] == 'exit';
    final color = isEntry
        ? const Color(0xFF0D9488)
        : isExit
        ? const Color(0xFFDC2626)
        : const Color(0xFF4F46E5);
    final bg = isEntry
        ? const Color(0xFFECFDF5)
        : isExit
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF5F3FF);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isEntry
                ? Icons.arrow_downward
                : isExit
                ? Icons.arrow_upward
                : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['concept'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    _dateTime(item['date']),
                    if ('${item['company'] ?? ''}'.isNotEmpty)
                      '${item['company']}',
                    if ('${item['employee'] ?? ''}'.isNotEmpty)
                      '${item['employee']}',
                  ].join(' | '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _signedCurrency(item),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _inputDecoration(),
            child: Row(
              children: [
                Expanded(child: Text(_uiDate(value))),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _exportButton(
    String label,
    IconData icon,
    Color color,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          label: Text(label, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _employerCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item['employer_name'] ?? ''} | CC ${item['employer_document'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${_toInt(item['employees'])} empleados',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Chip(label: Text('${_toInt(item['requests'])} solicitudes')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Desembolsado',
                  _currency(item['disbursed']),
                  const Color(0xFFECFDF5),
                  const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Recuperado',
                  _currency(item['recovered']),
                  const Color(0xFFF5F3FF),
                  const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Ganancias',
                  _currency(item['earnings']),
                  const Color(0xFFF3E8FF),
                  const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Fees',
                  _currency(item['fees']),
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Intereses',
                  _currency(item['interest']),
                  const Color(0xFFFFF1F2),
                  const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  'Suscripciones',
                  _currency(item['subscriptions']),
                  const Color(0xFFECFDF5),
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return _card(
      child: Text(error, style: const TextStyle(color: Color(0xFF991B1B))),
    );
  }
}
