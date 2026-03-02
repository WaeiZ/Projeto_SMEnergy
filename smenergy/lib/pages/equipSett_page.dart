import 'package:flutter/material.dart';
import 'package:smenergy/pages/History_page.dart';
import 'package:smenergy/pages/alert_page.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/pages/profile_page.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class EquipSettPage extends StatefulWidget {
  const EquipSettPage({super.key});

  @override
  State<EquipSettPage> createState() => _EquipSettPageState();
}

class _EquipSettPageState extends State<EquipSettPage> {
  int _selectedIndex = 3;
  final EnergyDataService _energyDataService = EnergyDataService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  List<_EditableSensor> _editableSensors = [];

  @override
  void initState() {
    super.initState();
    _loadSensorSettings();
  }

  @override
  void dispose() {
    _disposeSensorControllers();
    super.dispose();
  }

  void _disposeSensorControllers() {
    for (final sensor in _editableSensors) {
      sensor.dispose();
    }
  }

  Future<void> _loadSensorSettings() async {
    try {
      await _energyDataService.seedDemoDataIfEmpty();
      final sensors = await _energyDataService.fetchSensorSettings();
      if (!mounted) return;

      final editable = sensors
          .map(
            (sensor) => _EditableSensor(
              id: sensor.id,
              initialName: sensor.name,
              initialLimitWatts: sensor.limitWatts,
            ),
          )
          .toList(growable: false);

      setState(() {
        _disposeSensorControllers();
        _editableSensors = editable;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Não foi possível carregar os sensores da Firebase.';
      });
    }
  }

  Future<void> _saveSensorSettings() async {
    if (_isSaving || _editableSensors.isEmpty) return;

    final updates = <EnergySensorSettings>[];
    for (int i = 0; i < _editableSensors.length; i++) {
      final sensor = _editableSensors[i];
      final name = sensor.nameController.text.trim();
      final limitText = sensor.limitController.text.trim().replaceAll(',', '.');
      final limitWatts = double.tryParse(limitText);

      if (name.isEmpty) {
        _showSnackBar('Nome inválido no Sensor ${i + 1}.');
        return;
      }
      if (limitWatts == null || limitWatts <= 0) {
        _showSnackBar('Limite inválido no Sensor ${i + 1}.');
        return;
      }

      updates.add(
        EnergySensorSettings(id: sensor.id, name: name, limitWatts: limitWatts),
      );
    }

    setState(() => _isSaving = true);
    try {
      await _energyDataService.updateSensorSettings(updates);
      if (!mounted) return;
      _showSnackBar('Definições de sensores guardadas com sucesso.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Falha ao guardar definições na Firebase.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (_loadError != null) ...[
                    Text(
                      _loadError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_editableSensors.isEmpty)
                    const Text(
                      'Sem sensores disponíveis para configuração.',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    )
                  else
                    ..._buildSensorInputs(myGradient),
                  const SizedBox(height: 24),
                  CustomGradientButton(
                    text: _isSaving ? 'A guardar...' : 'Confirmar',
                    gradient: myGradient,
                    onPressed: _saveSensorSettings,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  List<Widget> _buildSensorInputs(LinearGradient gradient) {
    final widgets = <Widget>[];
    for (int i = 0; i < _editableSensors.length; i++) {
      final sensor = _editableSensors[i];
      widgets.add(
        Text(
          'Sensor ${i + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        CustomPopOutInput(
          controller: sensor.nameController,
          icon: Icons.bolt,
          hint: 'Nome do sensor',
          gradient: gradient,
        ),
      );
      widgets.add(const SizedBox(height: 12));
      widgets.add(
        CustomPopOutInput(
          controller: sensor.limitController,
          icon: Icons.notifications,
          hint: 'Limite (W)',
          gradient: gradient,
        ),
      );
      widgets.add(const SizedBox(height: 18));
    }
    return widgets;
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

class _EditableSensor {
  _EditableSensor({
    required this.id,
    required String initialName,
    required double initialLimitWatts,
  }) : nameController = TextEditingController(text: initialName),
       limitController = TextEditingController(
         text: initialLimitWatts.toStringAsFixed(0),
       );

  final String id;
  final TextEditingController nameController;
  final TextEditingController limitController;

  void dispose() {
    nameController.dispose();
    limitController.dispose();
  }
}
