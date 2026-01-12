import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();
  int _currentSensorIndex = 0;

  // Lista mock de sensores para teste
  final List<Map<String, dynamic>> _sensors = [
    {'name': 'Sensor 1', 'watts': 500, 'progress': 0.7},
    {'name': 'Sensor 2', 'watts': 320, 'progress': 0.4},
    {'name': 'Sensor 3', 'watts': 850, 'progress': 0.9},
  ];

  @override
  Widget build(BuildContext context) {
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

            _buildMainGauge(),

            const SizedBox(height: 30),

            // Gráfico
            _buildConsumptionChart(),

            const SizedBox(height: 20),

            // Cards de estado
            Row(
              children: [
                _buildInfoCard(
                  title: 'Total do dia',
                  value: '45.2 KWh',
                  icon: Icons.bolt,
                  color: const Color(0xFFE3F0FE),
                  iconColor: Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildInfoCard(
                  title: 'Estado',
                  value: 'Online',
                  icon: Icons.devices,
                  color: const Color(0xFFE3F0FE),
                  iconColor: Colors.blue,
                  isStatus: true,
                ),
              ],
            ),

            // O Spacer() ajuda a empurrar o conteúdo para cima se sobrar espaço
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainGauge() {
    return Column(
      children: [
        SizedBox(
          height: 320, // Aumentado de 260 para 320 para caber o círculo maior
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentSensorIndex = index;
              });
            },
            itemCount: _sensors.length,
            itemBuilder: (context, index) {
              final sensor = _sensors[index];
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // --- ANEL DE PROGRESSO MAIOR ---
                    SizedBox(
                      width: 300, // Aumentado de 250 para 300
                      height: 300, // Aumentado de 250 para 300
                      child: CircularProgressIndicator(
                        value: sensor['progress'],
                        strokeWidth:
                            15, // Aumentei a espessura para acompanhar o tamanho
                        backgroundColor: Colors.grey[100],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3DA5FA),
                        ),
                      ),
                    ),

                    // --- TEXTOS INTERNOS ---
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: Color(0xFF3DA5FA),
                          size: 50,
                        ), // Ícone maior
                        Text(
                          sensor['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ), // Fonte maior
                        ),
                        Text(
                          '${sensor['watts']} W',
                          style: const TextStyle(
                            fontSize: 44, // Aumentado de 36 para 44
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
        // Indicador de Pontos
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _sensors.length,
            (index) => _buildDot(index == _currentSensorIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Suaviza a troca do ponto
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 6, // Opcional: aumenta o ponto ativo
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3DA5FA) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Widget do Gráfico de Linha
  Widget _buildConsumptionChart() {
    return Container(
      height: 220, // Altura ligeiramente maior para caberem os textos dos eixos
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3F0FE)),
      ),
      child: LineChart(
        LineChartData(
          // Configuração da grelha (linhas pontilhadas)
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
          // Configuração dos Títulos (Eixos)
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
                    case 23:
                      return const Text(
                        'Now',
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
          maxX: 24, // 24 horas do dia
          minY: 0,
          maxY: 8, // Ajusta conforme o consumo máximo esperado em kW
          lineBarsData: [
            LineChartBarData(
              // Dados Mock: No futuro, estes pontos virão do teu banco de dados
              spots: [
                FlSpot(0, 2),
                FlSpot(3, 1.8),
                FlSpot(6, 2.2),
                FlSpot(9, 3.5),
                FlSpot(12, 4.2),
                FlSpot(15, 5.0),
                FlSpot(18, 7.0), // Ponto alto (ex: hora de jantar)
                FlSpot(20, 4.5), // O gráfico para aqui se forem 20h
              ],
              isCurved: true,
              color: const Color(0xFF1D7EF8),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(
                show: false,
              ), // Remove os pontos na linha
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1D7EF8).withOpacity(0.3),
                    const Color(0xFF1D7EF8).withOpacity(0.0),
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

  // Widget dos Cards Inferiores
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
    bool isStatus = false,
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
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
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

  // Bottom Navigation Bar
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) => setState(() => _selectedIndex = index),
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
    bool isSelected = _selectedIndex == index;
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
