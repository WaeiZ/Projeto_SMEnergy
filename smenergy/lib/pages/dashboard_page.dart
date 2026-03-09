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
        final data = snapshot.data ?? const EnergyDashboardData.empty();
        final sensors = data.sensors;
        final chartPoints = data.chartPoints;
        final allOnline =
            sensors.isNotEmpty && sensors.every((sensor) => sensor.isOnline);

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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildMainGauge(sensors),
                const SizedBox(height: 30),
                _buildConsumptionChart(chartPoints),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoCard(
                      title: 'Total do dia',
                      value: '${data.totalDayKwh.toStringAsFixed(1)} KWh',
                      icon: Icons.bolt,
                      color: const Color(0xFFE3F0FE),
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(width: 15),
                    _buildInfoCard(
                      title: 'Estado',
                      value: allOnline ? 'Online' : 'Parcial',
                      icon: Icons.devices,
                      color: const Color(0xFFE3F0FE),
                      iconColor: Colors.blue,
                      isStatus: true,
                      statusColor: allOnline
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ],
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Erro ao carregar dados da Firebase.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildMainGauge(List<EnergySensorSnapshot> sensors) {
    final selectedIndex = sensors.isEmpty
        ? 0
        : min(_currentSensorIndex, sensors.length - 1);

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: sensors.isEmpty
              ? const Center(
                  child: Text(
                    'Sem leituras na Firebase para este utilizador.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSensorIndex = index;
                    });
                  },
                  itemCount: sensors.length,
                  itemBuilder: (context, index) {
                    final sensor = sensors[index];
                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: CircularProgressIndicator(
                              value: sensor.progress,
                              strokeWidth: 15,
                              backgroundColor: Colors.grey[100],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF3DA5FA),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Color(0xFF3DA5FA),
                                size: 50,
                              ),
                              Text(
                                sensor.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${sensor.watts.toInt()} W',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            sensors.length,
            (index) => _buildDot(index == selectedIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3DA5FA) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildConsumptionChart(List<EnergyChartPoint> chartPoints) {
    final points = chartPoints
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final spots = points.isEmpty ? const [FlSpot(0, 0), FlSpot(21, 0)] : points;
    final maxY = max(
      8.0,
      spots.map((spot) => spot.y).reduce(max).ceilToDouble() + 1,
    );

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3F0FE)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 2,
            verticalInterval: 6,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey[200]!,
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
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text(
                        '00:00',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    case 6:
                      return const Text(
                        '06:00',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    case 12:
                      return const Text(
                        '12:00',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    case 18:
                      return const Text(
                        '18:00',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    case 21:
                      return const Text(
                        'Agora',
                        style: TextStyle(
                          color: Color(0xFF3DA5FA),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 24,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1D7EF8),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1D7EF8).withValues(alpha: 0.3),
                    const Color(0xFF1D7EF8).withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
    bool isStatus = false,
    Color statusColor = Colors.greenAccent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (isStatus) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
