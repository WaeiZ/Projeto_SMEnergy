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
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3DA5FA),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3DA5FA),
                    size: 38,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Sérgio Dias',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressCard(),
            const SizedBox(height: 16),
            _buildElectricityCard(),
            const SizedBox(height: 12),
            CustomGradientButton(
              text: 'Definições de Eletricidade',
              gradient: myGradient,
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ElectricitySettingsPage(),
                  ),
                );
                if (updated == true) {
                  _loadElectricityProfile();
                }
              },
            ),
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

  Widget _buildProgressCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GamificationPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3DA5FA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Nível:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3DA5FA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pulse',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _buildLevelBadge(),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Progresso',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DA5FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '500/1000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressBar(value: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElectricityCard() {
    if (_isLoadingElectricity) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3DA5FA)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _electricityProfile;

    return Container(
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
          const Text(
            'Definições de Eletricidade',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF3DA5FA),
              fontWeight: FontWeight.bold,
            ),
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
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3DA5FA), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 16,
          backgroundColor: const Color(0xFFE6F2FF),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF3DA5FA)),
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3DA5FA),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
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
