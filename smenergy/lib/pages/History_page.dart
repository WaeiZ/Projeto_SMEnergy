import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
  String? _loadError;

  List<double> _chartValues = [];
  List<String> _chartLabels = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _energyDataService.seedDemoDataIfEmpty();
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
        _chartValues = [];
        _chartLabels = [];
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
        _chartValues = data.values;
        _chartLabels = data.labels;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Erro ao ler histórico da Firebase.';
        _chartValues = [];
        _chartLabels = [];
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
                  const Text(
                    'Selecionar Medida',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                    text: 'Exportar PDF',
                    gradient: myGradient,
                    onPressed: () {},
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

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedSensorId,
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
    );
  }

  Widget _buildMeasureDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedMeasure,
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
            enabled: false,
            handleBuiltInTouches: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 6,
              getTooltipColor: (group) => Colors.transparent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toStringAsFixed(0),
                  const TextStyle(
                    color: Color(0xFF8C9BB5),
                    fontSize: 12,
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
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _chartLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _chartLabels[index],
                    style: const TextStyle(
                      color: Color(0xFF8C9BB5),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(
      _chartValues.length,
      (index) => BarChartGroupData(
        x: index,
        showingTooltipIndicators: const [0],
        barRods: [
          BarChartRodData(
            toY: _chartValues[index],
            width: 18,
            color: const Color(0xFF3DA5FA),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
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
