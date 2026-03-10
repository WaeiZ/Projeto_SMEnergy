import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/energy_data_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _currentSensorIndex = 0;

  final PageController _pageController = PageController();
  final EnergyDataService _energyDataService = EnergyDataService();
  late final Stream<EnergyDashboardData> _dashboardStream;

  @override
  void initState() {
    super.initState();
    _dashboardStream = _energyDataService.streamDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EnergyDashboardData>(
      stream: _dashboardStream,
      builder: (context, snapshot) {
        final isInitialLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final data = snapshot.data ?? const EnergyDashboardData.empty();
        final sensors = data.sensors;
        final chartPoints = data.chartPoints;
        final onlineCount = sensors.where((sensor) => sensor.isOnline).length;
        final allOnline =
            sensors.isNotEmpty && sensors.every((sensor) => sensor.isOnline);
        final statusLabel = sensors.isEmpty
            ? 'Sem dados'
            : allOnline
            ? 'Online'
            : onlineCount == 0
            ? 'Offline'
            : 'Parcial';
        final statusColor = sensors.isEmpty
            ? const Color(0xFFB7C5D8)
            : allOnline
            ? const Color(0xFF2BC66A)
            : onlineCount == 0
            ? const Color(0xFFFF7A59)
            : const Color(0xFFFFB648);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: false,
          ),
          body: isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainGauge(sensors),
                      const SizedBox(height: 20),
                      _buildConsumptionChart(chartPoints),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoCard(
                            title: 'Total do dia',
                            value: '${data.totalDayKwh.toStringAsFixed(1)} kWh',
                            subtitle: 'Energia acumulada hoje',
                            icon: Icons.bolt,
                            iconColor: const Color(0xFF1D7EF8),
                          ),
                          const SizedBox(width: 15),
                          _buildInfoCard(
                            title: 'Conectividade',
                            value: statusLabel,
                            subtitle: sensors.isEmpty
                                ? 'Sem sensores ativos'
                                : '$onlineCount/${sensors.length} sensores online',
                            icon: Icons.wifi_tethering_rounded,
                            iconColor: statusColor,
                            statusColor: statusColor,
                          ),
                        ],
                      ),
                      if (snapshot.hasError) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Erro ao carregar dados da Firebase.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildMainGauge(List<EnergySensorSnapshot> sensors) {
    if (sensors.isEmpty) {
      return _buildEmptyStateCard(
        title: 'Dashboard sem leituras',
        description:
            'Liga um equipamento ou aguarda novas medições para veres consumo em tempo real.',
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final compactLayout = screenSize.width < 380 || screenSize.height < 820;
    final cardHeight = compactLayout ? 560.0 : 610.0;
    final selectedIndex = min(_currentSensorIndex, sensors.length - 1);

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentSensorIndex = index;
              });
            },
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final sensor = sensors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildSensorHeroCard(
                  sensor,
                  position: index + 1,
                  total: sensors.length,
                  compactLayout: compactLayout,
                ),
              );
            },
          ),
        ),
        if (sensors.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              sensors.length,
              (index) => _buildDot(index == selectedIndex),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Desliza para alternar sensor',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF7C8CA8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSensorHeroCard(
    EnergySensorSnapshot sensor, {
    required int position,
    required int total,
    required bool compactLayout,
  }) {
    final accentColor = sensor.isAlert
        ? const Color(0xFFFF7A59)
        : sensor.isOnline
        ? const Color(0xFF1D7EF8)
        : const Color(0xFF8C9BB5);
    final usagePercent = (sensor.progress * 100).round();
    final statusLabel = sensor.isOnline ? 'Online' : 'Offline';
    final marginWatts = sensor.isAlert
        ? '+${sensor.excessWatts.toStringAsFixed(0)} W acima do limite'
        : '${max(0, sensor.limitWatts - sensor.watts).toStringAsFixed(0)} W livres';
    final gaugeSize = compactLayout ? 190.0 : 220.0;
    final gaugeInnerSize = compactLayout ? 168.0 : 196.0;
    final cardPadding = compactLayout ? 16.0 : 18.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FBFF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3DA5FA).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensor em foco',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C8CA8),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sensor.name,
                      style: TextStyle(
                        fontSize: compactLayout ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2F3443),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusPill(
                          statusLabel,
                          color: accentColor,
                          backgroundColor: accentColor.withValues(alpha: 0.12),
                        ),
                        _buildStatusPill(
                          'Limite ${sensor.limitWatts.toStringAsFixed(0)} W',
                          color: const Color(0xFF6C86A2),
                          backgroundColor: Colors.white,
                          borderColor: const Color(0xFFDCEBFF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDCEBFF)),
                ),
                child: Text(
                  '$position/$total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D7EF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: gaugeSize,
              height: gaugeSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: gaugeInnerSize,
                    height: gaugeInnerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: gaugeSize,
                    height: gaugeSize,
                    child: CircularProgressIndicator(
                      value: sensor.progress,
                      strokeWidth: compactLayout ? 12 : 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE7F1FE),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sensor.isAlert
                            ? Icons.warning_amber_rounded
                            : Icons.bolt_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${sensor.watts.toStringAsFixed(0)} W',
                        style: TextStyle(
                          fontSize: compactLayout ? 28 : 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2F3443),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consumo atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: sensor.isAlert
                              ? const Color(0xFFFF7A59)
                              : const Color(0xFF7C8CA8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSensorMetricCard(
                  label: 'Hoje',
                  value: '${sensor.dailyKwh.toStringAsFixed(1)} kWh',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSensorMetricCard(
                  label: 'Carga',
                  value: '$usagePercent%',
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCEBFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sensor.isAlert ? Icons.priority_high_rounded : Icons.tune,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.isAlert
                            ? 'Acima do limite configurado'
                            : 'Margem disponível',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C8CA8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        marginWatts,
                        style: TextStyle(
                          fontSize: compactLayout ? 14 : 15,
                          color: const Color(0xFF2F3443),
                          fontWeight: FontWeight.w700,
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

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3DA5FA) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildConsumptionChart(List<EnergyChartPoint> chartPoints) {
    if (chartPoints.isEmpty) {
      return _buildEmptyStateCard(
        title: 'Sem série temporal',
        description:
            'Ainda não há dados suficientes para desenhar o gráfico de consumo diário.',
      );
    }

    final spots = chartPoints
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final highestValue = spots.map((spot) => spot.y).reduce(max);
    final maxY = _computeChartMaxY(highestValue);
    final interval = _computeChartInterval(maxY);
    final averageKw =
        spots.fold<double>(0, (acc, spot) => acc + spot.y) / spots.length;
    final latestKw = spots.last.y;
    final peakKw = highestValue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3DA5FA).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consumo ao longo do dia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F3443),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Potência agregada por blocos de 3 horas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C8CA8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildChartHighlight(
                label: 'Pico',
                value: '${peakKw.toStringAsFixed(1)} kW',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFE9EEF5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _formatChartAxis(value),
                          style: const TextStyle(
                            color: Color(0xFF8C9BB5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final hasMatch = chartPoints.any(
                          (point) => point.x.toInt() == value.toInt(),
                        );
                        if (!hasMatch) {
                          return const SizedBox.shrink();
                        }
                        final isLatest = value.toInt() == spots.last.x.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatDashboardHourLabel(value.toInt()),
                            style: TextStyle(
                              color: isLatest
                                  ? const Color(0xFF1D7EF8)
                                  : const Color(0xFF8C9BB5),
                              fontWeight: isLatest
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: spots.first.x,
                maxX: spots.last.x,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E2A3A),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${_formatDashboardHourLabel(spot.x.toInt())}\n${spot.y.toStringAsFixed(1)} kW',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: const Color(0xFF1D7EF8),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) =>
                          spot == spots.last || spot.y == peakKw,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLatest = spot == spots.last;
                        return FlDotCirclePainter(
                          radius: isLatest ? 4.5 : 3.5,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF1D7EF8),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1D7EF8).withValues(alpha: 0.22),
                          const Color(0xFF1D7EF8).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildChartFooterMetric(
                  label: 'Agora',
                  value: '${latestKw.toStringAsFixed(1)} kW',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChartFooterMetric(
                  label: 'Média',
                  value: '${averageKw.toStringAsFixed(1)} kW',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Color(0xFF1D7EF8),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F3443),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C8CA8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    String text, {
    required Color color,
    required Color backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSensorMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1D7EF8)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7C8CA8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F3443),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartHighlight({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7C8CA8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2F3443),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartFooterMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7C8CA8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2F3443),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  double _computeChartMaxY(double highestValue) {
    final interval = _computeChartInterval(max(highestValue, 0.5));
    return max(interval * 4, (highestValue / interval).ceil() * interval);
  }

  double _computeChartInterval(double highestValue) {
    const candidates = <double>[0.25, 0.5, 1, 2, 5, 10, 20];
    final raw = max(0.25, highestValue / 4);
    for (final candidate in candidates) {
      if (raw <= candidate) {
        return candidate;
      }
    }
    return (raw / 5).ceil() * 5;
  }

  String _formatChartAxis(double value) {
    if (value >= 10) {
      return value.toStringAsFixed(0);
    }
    if (value >= 1) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  String _formatDashboardHourLabel(int hour) {
    return '${hour.toString().padLeft(2, '0')}h';
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? statusColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCEBFF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3DA5FA).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                if (statusColor != null)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7C8CA8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF2F3443),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7C8CA8),
                height: 1.35,
              ),
            ),
          ],
        ),
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
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
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
}
