import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class EquipSettPage extends StatefulWidget {
  const EquipSettPage({super.key});

  @override
  State<EquipSettPage> createState() => _EquipSettPageState();
}

class _EquipSettPageState extends State<EquipSettPage> {
  int _selectedIndex = 3;

  final TextEditingController _sensor1Name = TextEditingController(text: 'Sensor 1');
  final TextEditingController _sensor1Limit = TextEditingController();
  final TextEditingController _sensor2Name = TextEditingController(text: 'Sensor 2');
  final TextEditingController _sensor2Limit = TextEditingController();
  final TextEditingController _sensor3Name = TextEditingController(text: 'Sensor 3');
  final TextEditingController _sensor3Limit = TextEditingController();

  @override
  void dispose() {
    _sensor1Name.dispose();
    _sensor1Limit.dispose();
    _sensor2Name.dispose();
    _sensor2Limit.dispose();
    _sensor3Name.dispose();
    _sensor3Limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

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
          'Equipamento',
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
            const Text(
              'Sensor 1',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomPopOutInput(
              controller: _sensor1Name,
              icon: Icons.bolt,
              hint: 'Sensor 1',
              gradient: myGradient,
            ),
            const SizedBox(height: 12),
            CustomPopOutInput(
              controller: _sensor1Limit,
              icon: Icons.notifications,
              hint: 'Limite Sensor 1',
              gradient: myGradient,
            ),
            const SizedBox(height: 18),
            const Text(
              'Sensor 2',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomPopOutInput(
              controller: _sensor2Name,
              icon: Icons.bolt,
              hint: 'Sensor 2',
              gradient: myGradient,
            ),
            const SizedBox(height: 12),
            CustomPopOutInput(
              controller: _sensor2Limit,
              icon: Icons.notifications,
              hint: 'Limite Sensor 2',
              gradient: myGradient,
            ),
            const SizedBox(height: 18),
            const Text(
              'Sensor 3',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomPopOutInput(
              controller: _sensor3Name,
              icon: Icons.bolt,
              hint: 'Sensor 3',
              gradient: myGradient,
            ),
            const SizedBox(height: 12),
            CustomPopOutInput(
              controller: _sensor3Limit,
              icon: Icons.notifications,
              hint: 'Limite Sensor 3',
              gradient: myGradient,
            ),
            const SizedBox(height: 24),
            CustomGradientButton(
              text: 'Confirmar',
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
