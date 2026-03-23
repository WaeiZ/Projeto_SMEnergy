import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/energy_data_service.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  int _selectedIndex = 2;

  final EnergyDataService _energyDataService = EnergyDataService();
  late final Stream<EnergyAlertData> _alertStream;
  bool _isApplyingReward = false;

  @override
  void initState() {
    super.initState();
    _alertStream = _energyDataService.streamAlertData();
  }

  Future<void> _verifyActiveAlert(EnergyActiveAlert alert) async {
    if (_isApplyingReward) return;

    setState(() => _isApplyingReward = true);
    try {
      final profile = await _energyDataService.addGamificationPoints(
        alert.rewardPoints,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+${alert.rewardPoints} pontos atribuídos. Total atual: ${profile.points}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os pontos agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplyingReward = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EnergyAlertData>(
      stream: _alertStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const EnergyAlertData.empty();
        final alertCount = data.statuses
            .where((status) => status.isAlert)
            .length;
        final okCount = data.statuses.length - alertCount;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Alertas',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildOverviewCard(
                  totalSensors: data.statuses.length,
                  alertCount: alertCount,
                  okCount: okCount,
                  hasActiveAlert: data.activeAlert != null,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Alerta ativo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.activeAlert != null)
                  _buildActiveAlertCard(data.activeAlert!)
                else
                  _buildNoActiveAlertCard(),
                const SizedBox(height: 20),
                const Text(
                  'Estado sensores',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.statuses.isEmpty)
                  _buildEmptySensorCard()
                else
                  ...data.statuses.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSensorStatusCard(
                        title: status.sensorName,
                        status: status.statusLabel,
                        isAlert: status.isAlert,
                      ),
                    ),
                  ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Erro ao carregar alertas da Firebase.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required int totalSensors,
    required int alertCount,
    required int okCount,
    required bool hasActiveAlert,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasActiveAlert
                      ? const Color(0xFFFFE4DD)
                      : const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasActiveAlert
                      ? Icons.warning_amber_rounded
                      : Icons.shield_outlined,
                  color: hasActiveAlert
                      ? const Color(0xFFFF6B55)
                      : const Color(0xFF1D7EF8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitorização',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C86A2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActiveAlert
                          ? 'Consumo excessivo detetado'
                          : 'Tudo estável neste momento',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F3443),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasActiveAlert
                ? 'Revemos os sensores que estão acima do limite e podes validar o alerta diretamente aqui.'
                : 'A página continua a acompanhar os sensores e mostra-te logo que houver consumo acima do limite.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6C86A2),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  label: 'Sensores',
                  value: '$totalSensors',
                  accentColor: const Color(0xFF1D7EF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStat(
                  label: 'Em alerta',
                  value: '$alertCount',
                  accentColor: const Color(0xFFFF6B55),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStat(
                  label: 'Estáveis',
                  value: '$okCount',
                  accentColor: const Color(0xFF2BC66A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Color(0xFF6C86A2),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertCard(EnergyActiveAlert alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFEA), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFFFF6B55)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2D8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B55),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ação necessária',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF2F3443),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFD5CB)),
            ),
            child: Text(
              'Sensor: ${alert.sensorName}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6B55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            alert.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5A6475),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD5CB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recompensa',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C86A2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert.rewardPoints} pontos',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFFF6B55),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingReward
                      ? null
                      : () => _verifyActiveAlert(alert),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B55),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isApplyingReward
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Verificar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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

  Widget _buildNoActiveAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF1D7EF8), size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Sem alertas ativos no momento. Continuamos a vigiar os sensores em tempo real.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF2F3443),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySensorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: const Text(
        'Sem sensores disponíveis na Firebase.',
        style: TextStyle(
          color: Color(0xFF6C86A2),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSensorStatusCard({
    required String title,
    required String status,
    required bool isAlert,
  }) {
    final accentColor = isAlert
        ? const Color(0xFFFF6B55)
        : const Color(0xFF1D7EF8);
    final icon = isAlert ? Icons.warning_amber_rounded : Icons.check_circle;
    final subtitle = isAlert
        ? 'Acima do limite configurado'
        : 'Dentro do limite configurado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCEBFF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F3443),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C86A2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
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
