import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/change_pass_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class AccSettPage extends StatefulWidget {
  const AccSettPage({super.key});

  @override
  State<AccSettPage> createState() => _AccSettPageState();
}

class _AccSettPageState extends State<AccSettPage> {
  int _selectedIndex = 3;
  final TextEditingController _nameController =
      TextEditingController(text: 'Sérgio Dias');

  @override
  void dispose() {
    _nameController.dispose();
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
          'Definições da conta',
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
          children: [
            const SizedBox(height: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3DA5FA), width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF3DA5FA),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            CustomPopOutInput(
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Nome',
              gradient: myGradient,
            ),
            const SizedBox(height: 24),
            CustomGradientButton(
              text: 'Redefinir Password',
              gradient: myGradient,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePassPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomGradientButton(
              text: 'Eliminar Conta',
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
