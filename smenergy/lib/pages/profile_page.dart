import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/acc_sett_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/electricity_settings_page.dart';
import 'package:smenergy/pages/equipSett_page.dart';
import 'package:smenergy/pages/gamification_page.dart';
import 'package:smenergy/pages/login_page.dart';
import 'package:smenergy/services/auth_service.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  final AuthService _authService = AuthService();
  final EnergyDataService _energyDataService = EnergyDataService();

  bool _isLoadingElectricity = true;
  ElectricityCostProfile _electricityProfile =
      const ElectricityCostProfile.empty();

  @override
  void initState() {
    super.initState();
    _loadElectricityProfile();
  }

  Future<void> _loadElectricityProfile() async {
    try {
      final profile = await _energyDataService.fetchElectricityCostProfile();
      if (!mounted) return;
      setState(() {
        _electricityProfile = profile;
        _isLoadingElectricity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingElectricity = false);
    }
  }

  Future<void> _openElectricitySettings() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ElectricitySettingsPage()),
    );

    if (updated == true) {
      _loadElectricityProfile();
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
          'Perfil',
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
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildProgressCard(),
            const SizedBox(height: 16),
            _buildElectricityCard(),
            const SizedBox(height: 12),
            CustomGradientButton(
              text: 'Definições do Equipamento',
              gradient: myGradient,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EquipSettPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomGradientButton(
              text: 'Definições da Conta',
              gradient: myGradient,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccSettPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOutlineButton(
              'Logout',
              onTap: () async {
                await _authService.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppGradients.blueLinear,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3DA5FA).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Container(
                margin: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF4FF),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1D7EF8),
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sérgio Dias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2F3443),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conta SMEnergy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C86A2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFF1D7EF8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Perfil ativo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F3443),
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

  Widget _buildProgressCard() {
    const currentPoints = 500;
    const targetPoints = 1000;
    const levelName = 'Pulse';
    final progress = currentPoints / targetPoints;
    final progressPercent = (progress * 100).round();
    final missingPoints = targetPoints - currentPoints;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GamificationPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3DA5FA), width: 1.2),
            color: const Color(0xFFF7FBFF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3DA5FA).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                        const Text(
                          'Gamificação',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C86A2),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              levelName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2F3443),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFDCEBFF),
                                ),
                              ),
                              child: const Text(
                                'Nível atual',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D7EF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Faltam $missingPoints pontos para o próximo objetivo.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C86A2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLevelBadge(levelName),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCEBFF)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Progresso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F3443),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D7EF8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildProgressPill('$currentPoints/$targetPoints'),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProgressBar(value: progress)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Próximo nível: 1000',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C86A2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF6C86A2),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppGradients.blueLinear,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildElectricityCard() {
    if (_isLoadingElectricity) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openElectricitySettings,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3DA5FA)),
              color: const Color(0xFFF7FBFF),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final profile = _electricityProfile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openElectricitySettings,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3DA5FA)),
            color: const Color(0xFFF7FBFF),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Definições de Eletricidade',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3DA5FA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF3DA5FA),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!profile.isConfigured)
                const Text(
                  'Ainda não configuraste o teu contrato elétrico.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildElectricityMetric(
                        'Contrato',
                        profile.contractType.label,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildElectricityMetric(
                        'Consumo mensal',
                        '${profile.totalMonthlyConsumptionKwh.toStringAsFixed(1)} kWh',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildElectricityMetric(
                  'Custo estimado',
                  '${profile.estimatedCostEur.toStringAsFixed(2)} € / mês',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElectricityMetric(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({required double value}) {
    final safeValue = value.clamp(0.0, 1.0);

    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * safeValue,
                decoration: BoxDecoration(
                  gradient: AppGradients.blueLinear,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLevelBadge(String levelName) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppGradients.blueLinear,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3DA5FA).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF4FF),
              border: Border.all(color: const Color(0xFF3DA5FA), width: 1.4),
            ),
            child: _buildLevelAssetIcon(levelName),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelAssetIcon(String levelName) {
    final asset = switch (levelName.toLowerCase()) {
      'pulse' => 'assets/icons/pulse_icon.png',
      'volt' => 'assets/icons/volt_icon.png',
      'zeus' => 'assets/icons/zeus_icon.png',
      _ => 'assets/icons/pulse_icon.png',
    };

    final fallback = switch (levelName.toLowerCase()) {
      'pulse' => Icons.radio_button_checked,
      'volt' => Icons.bolt_rounded,
      'zeus' => Icons.workspace_premium_rounded,
      _ => Icons.radio_button_checked,
    };

    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallback, color: const Color(0xFF1D7EF8), size: 18);
      },
    );
  }

  Widget _buildOutlineButton(String text, {required VoidCallback onTap}) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3DA5FA), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

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
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AlertPage()),
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
