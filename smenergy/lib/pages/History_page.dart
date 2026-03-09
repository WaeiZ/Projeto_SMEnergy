import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final EnergyDataService _energyDataService = EnergyDataService();

  int _selectedIndex = 1;
  final List<String> _measures = ['Média', 'Máximo', 'Mínimo'];

  List<EnergySensorOption> _sensors = [];
  String? _selectedSensorId;
  String _selectedMeasure = 'Média';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  bool _isLoadingSensors = true;
  bool _isLoadingChart = false;
  bool _isExportingPdf = false;
  String? _loadError;

  EnergyHistoryData _historyData = const EnergyHistoryData.empty();

  List<double> get _chartValues => _historyData.values;
  List<String> get _chartLabels => _historyData.labels;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final sensors = await _energyDataService.fetchSensors();
      if (!mounted) return;

      setState(() {
        _sensors = sensors;
        _selectedSensorId = sensors.isNotEmpty ? sensors.first.id : null;
        _isLoadingSensors = false;
      });

      await _reloadChartData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSensors = false;
        _loadError = 'Não foi possível carregar sensores da Firebase.';
      });
    }
  }

  Future<void> _reloadChartData() async {
    if (_selectedSensorId == null) {
      if (!mounted) return;
      setState(() {
        _historyData = const EnergyHistoryData.empty();
      });
      return;
    }

    setState(() {
      _isLoadingChart = true;
      _loadError = null;
    });

    try {
      final data = await _energyDataService.fetchHistory(
        sensorId: _selectedSensorId!,
        measure: _selectedMeasure,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _historyData = data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Erro ao ler histórico da Firebase.';
        _historyData = const EnergyHistoryData.empty();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingChart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoadingSensors
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSensorDropdown(),
                  const SizedBox(height: 16),
                  _buildMeasureDropdown(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInput(
                          label: 'Data',
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildDateInput(
                          label: 'Data',
                          value: _formatDate(_endDate),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(),
                  const SizedBox(height: 16),
                  _buildAdditionalDataSection(),
                  if (_loadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  CustomGradientButton(
                    text: _isExportingPdf ? 'A exportar...' : 'Exportar PDF',
                    gradient: myGradient,
                    onPressed: _isExportingPdf ? () {} : _exportPdf,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSensorDropdown() {
    if (_sensors.isEmpty) {
      return const Text(
        'Sem sensores na Firebase.',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecionar Sensor',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSensorId,
          decoration: _selectionDecoration(),
          items: _sensors
              .map(
                (sensor) => DropdownMenuItem<String>(
                  value: sensor.id,
                  child: Text(
                    sensor.name,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedSensorId = value);
            _reloadChartData();
          },
        ),
      ],
    );
  }

  Widget _buildMeasureDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecionar Medida',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedMeasure,
          decoration: _selectionDecoration(),
          items: _measures
              .map(
                (measure) => DropdownMenuItem<String>(
                  value: measure,
                  child: Text(
                    measure,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedMeasure = value);
            _reloadChartData();
          },
        ),
      ],
    );
  }

  InputDecoration _selectionDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4E6FB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4E6FB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3DA5FA), width: 1.5),
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'DD/MM/YYYY',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_isLoadingChart) {
      return Container(
        height: 230,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3F0FE)),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (_chartValues.isEmpty || _chartLabels.isEmpty) {
      return Container(
        height: 230,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3F0FE)),
        ),
        child: const Text(
          'Sem dados no intervalo selecionado.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final highestValue = _chartValues.reduce(max);
    final maxY = max(100.0, (highestValue * 1.25).ceilToDouble());
    final interval = max(20.0, (maxY / 4).ceilToDouble());
    final barWidth = _chartValues.length <= 6 ? 18.0 : 16.0;

    return Container(
      height: 230,
      padding: const EdgeInsets.only(top: 16, left: 8, right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F0FE)),
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              tooltipMargin: 8,
              getTooltipColor: (_) => const Color(0xFF1E2A3A),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x;
                if (index < 0 || index >= _chartLabels.length) {
                  return null;
                }
                return BarTooltipItem(
                  '${_chartLabels[index]}\n${rod.toY.toStringAsFixed(1)} W',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFF8C9BB5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _chartLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _chartLabels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8C9BB5),
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(barWidth),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(double barWidth) {
    return List.generate(
      _chartValues.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _chartValues[index],
            width: barWidth,
            color: const Color(0xFF3DA5FA),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F0FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados Adicionais',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Amostras',
                  value: _historyData.sampleCount.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Média',
                  value: '${_historyData.averageWatts.toStringAsFixed(1)} W',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Máximo',
                  value: '${_historyData.maxWatts.toStringAsFixed(1)} W',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Mínimo',
                  value: '${_historyData.minWatts.toStringAsFixed(1)} W',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Consumo estimado',
                  value: '${_historyData.totalKwh.toStringAsFixed(2)} kWh',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Custo estimado',
                  value: _historyData.costConfigured
                      ? '${_historyData.estimatedCostEur.toStringAsFixed(2)} €'
                      : 'Configurar contrato',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String label, required String value}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7C8CA8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_selectedSensorId == null) {
      _showSnackBar('Selecione um sensor para exportar o histórico.');
      return;
    }
    if (_isExportingPdf) return;

    setState(() => _isExportingPdf = true);
    try {
      final sensorName = _selectedSensorName ?? _selectedSensorId!;
      final now = DateTime.now();
      final rows = List<List<String>>.generate(
        _chartLabels.length,
        (index) => [
          _chartLabels[index],
          _chartValues[index].toStringAsFixed(1),
        ],
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Relatório de Histórico SMEnergy',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Gerado em ${_formatDate(now)} às ${_formatHourMinute(now)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Sensor: $sensorName'),
                  pw.Text('Medida selecionada: $_selectedMeasure'),
                  pw.Text(
                    'Intervalo: ${_formatDate(_startDate)} a ${_formatDate(_endDate)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Resumo',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                _pdfSummaryRow('Amostras', _historyData.sampleCount.toString()),
                _pdfSummaryRow(
                  'Média',
                  '${_historyData.averageWatts.toStringAsFixed(1)} W',
                ),
                _pdfSummaryRow(
                  'Máximo',
                  '${_historyData.maxWatts.toStringAsFixed(1)} W',
                ),
                _pdfSummaryRow(
                  'Mínimo',
                  '${_historyData.minWatts.toStringAsFixed(1)} W',
                ),
                _pdfSummaryRow(
                  'Consumo estimado',
                  '${_historyData.totalKwh.toStringAsFixed(2)} kWh',
                ),
                _pdfSummaryRow(
                  'Contrato aplicado',
                  _historyData.costConfigured &&
                          _historyData.contractLabel.isNotEmpty
                      ? _historyData.contractLabel
                      : 'Não configurado',
                ),
                _pdfSummaryRow(
                  'Custo estimado',
                  _historyData.costConfigured
                      ? '${_historyData.estimatedCostEur.toStringAsFixed(2)} €'
                      : 'Não configurado',
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Dados do gráfico',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (rows.isEmpty)
              pw.Text('Sem dados disponíveis para o período selecionado.')
            else
              pw.TableHelper.fromTextArray(
                headers: const ['Data', 'Valor (W)'],
                data: rows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE3F0FE),
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.layoutPdf(
        name: _buildPdfName(sensorName, now),
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Não foi possível exportar o PDF.');
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  pw.TableRow _pdfSummaryRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value)),
      ],
    );
  }

  String _buildPdfName(String sensorName, DateTime at) {
    final lower = sensorName.trim().toLowerCase();
    final buffer = StringBuffer();
    bool previousUnderscore = false;
    for (final code in lower.codeUnits) {
      final isNumber = code >= 48 && code <= 57;
      final isLowercaseLetter = code >= 97 && code <= 122;
      if (isNumber || isLowercaseLetter) {
        buffer.writeCharCode(code);
        previousUnderscore = false;
      } else if (!previousUnderscore && buffer.isNotEmpty) {
        buffer.write('_');
        previousUnderscore = true;
      }
    }
    String safeSensor = buffer.toString();
    if (safeSensor.endsWith('_')) {
      safeSensor = safeSensor.substring(0, safeSensor.length - 1);
    }
    final ts =
        '${at.year}${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}_${at.hour.toString().padLeft(2, '0')}${at.minute.toString().padLeft(2, '0')}';
    return 'historico_${safeSensor.isEmpty ? 'sensor' : safeSensor}_$ts.pdf';
  }

  String _formatHourMinute(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? get _selectedSensorName {
    for (final sensor in _sensors) {
      if (sensor.id == _selectedSensorId) return sensor.name;
    }
    return null;
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE3F0FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
            return;
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AlertPage()),
            );
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        items: [
          _navItem(Icons.grid_view_rounded, 'Dashboard', 0),
          _navItem(Icons.bar_chart_rounded, 'Histórico', 1),
          _navItem(Icons.warning_amber_rounded, 'Alertas', 2),
          _navItem(Icons.person_outline, 'Perfil', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3DA5FA) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      ),
      label: label,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (picked.isAfter(_endDate)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (picked.isBefore(_startDate)) {
          _startDate = picked;
        }
      }
    });
    _reloadChartData();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
