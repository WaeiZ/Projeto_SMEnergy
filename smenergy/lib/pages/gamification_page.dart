import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gamificação',
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
            _buildLevelTimeline(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLevelTimeline() {
    const double cardHeight = 110;
    const double cardSpacing = 16;
    const double dotColumnWidth = 40;
    const double dotSize = 22;
    const double lineWidth = 3;
    const double lineInset = (cardHeight / 2) - (dotSize / 2);
    const double lineLeft = (dotColumnWidth / 2) - (lineWidth / 2);
    final totalHeight = (cardHeight * 3) + (cardSpacing * 2);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            left: lineLeft,
            top: lineInset,
            bottom: lineInset,
            child: Container(
              width: lineWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DCE3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Column(
            children: [
              _buildLevelRow(
                dotColumnWidth: dotColumnWidth,
                cardHeight: cardHeight,
                title: 'Pulse',
                points: '0 Pontos',
                isActive: true,
                child: _buildAssetIcon(
                  'assets/icons/pulse_icon.png',
                  fallback: Icons.radio_button_checked,
                  size: 64,
                ),
              ),
              const SizedBox(height: cardSpacing),
              _buildLevelRow(
                dotColumnWidth: dotColumnWidth,
                cardHeight: cardHeight,
                title: 'Volt',
                points: '1500 Pontos',
                isActive: false,
                child: _buildAssetIcon(
                  'assets/icons/volt_icon.png',
                  fallback: Icons.bolt,
                  size: 56,
                ),
              ),
              const SizedBox(height: cardSpacing),
              _buildLevelRow(
                dotColumnWidth: dotColumnWidth,
                cardHeight: cardHeight,
                title: 'Zeus',
                points: '3000 Pontos',
                isActive: false,
                child: _buildAssetIcon(
                  'assets/icons/zeus_icon.png',
                  fallback: Icons.account_circle,
                  size: 56,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow({
    required double dotColumnWidth,
    required double cardHeight,
    required String title,
    required String points,
    required bool isActive,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: dotColumnWidth,
          child: Align(
            alignment: Alignment.center,
            child: _buildTimelineDot(isActive: isActive),
          ),
        ),
        Expanded(
          child: Container(
            height: cardHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE6F2FF) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF3DA5FA), width: 1.5),
            ),
            child: Row(
              children: [
                child,
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        points,
                        style: const TextStyle(
                          color: Color(0xFF3DA5FA),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDot({required bool isActive}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
      ),
      child: isActive
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3DA5FA),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAssetIcon(String asset, {required IconData fallback, double size = 54}) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          fallback,
          color: const Color(0xFF3DA5FA),
          size: size,
        );
      },
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
