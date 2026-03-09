import 'package:flutter/material.dart';
import 'package:smenergy/services/energy_data_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class ElectricitySettingsPage extends StatefulWidget {
  const ElectricitySettingsPage({super.key});

  @override
  State<ElectricitySettingsPage> createState() =>
      _ElectricitySettingsPageState();
}

class _ElectricitySettingsPageState extends State<ElectricitySettingsPage> {
  final EnergyDataService _energyDataService = EnergyDataService();

  final TextEditingController _monthlyConsumptionController =
      TextEditingController();
  final TextEditingController _simpleTariffController = TextEditingController();
  final TextEditingController _peakConsumptionController =
      TextEditingController();
  final TextEditingController _offPeakConsumptionController =
      TextEditingController();
  final TextEditingController _superOffPeakConsumptionController =
      TextEditingController();
  final TextEditingController _peakTariffController = TextEditingController();
  final TextEditingController _offPeakTariffController =
      TextEditingController();
  final TextEditingController _superOffPeakTariffController =
      TextEditingController();
  final TextEditingController _peakScheduleController = TextEditingController();
  final TextEditingController _offPeakScheduleController =
      TextEditingController();
  final TextEditingController _superOffPeakScheduleController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  ElectricityContractType _contractType = ElectricityContractType.simple;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _monthlyConsumptionController.dispose();
    _simpleTariffController.dispose();
    _peakConsumptionController.dispose();
    _offPeakConsumptionController.dispose();
    _superOffPeakConsumptionController.dispose();
    _peakTariffController.dispose();
    _offPeakTariffController.dispose();
    _superOffPeakTariffController.dispose();
    _peakScheduleController.dispose();
    _offPeakScheduleController.dispose();
    _superOffPeakScheduleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _energyDataService.fetchElectricityCostProfile();
      if (!mounted) return;

      setState(() {
        _applyProfile(profile);
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Não foi possível carregar as definições de eletricidade.';
      });
    }
  }

  void _applyProfile(ElectricityCostProfile profile) {
    _contractType = profile.contractType;
    _monthlyConsumptionController.text = _formatInput(
      profile.monthlyConsumptionKwh,
    );
    _simpleTariffController.text = _formatInput(profile.simpleTariff);
    _peakConsumptionController.text = _formatInput(profile.peakConsumptionKwh);
    _offPeakConsumptionController.text = _formatInput(
      profile.offPeakConsumptionKwh,
    );
    _superOffPeakConsumptionController.text = _formatInput(
      profile.superOffPeakConsumptionKwh,
    );
    _peakTariffController.text = _formatInput(profile.peakTariff);
    _offPeakTariffController.text = _formatInput(profile.offPeakTariff);
    _superOffPeakTariffController.text = _formatInput(
      profile.superOffPeakTariff,
    );
    _peakScheduleController.text = profile.peakSchedule;
    _offPeakScheduleController.text = profile.offPeakSchedule;
    _superOffPeakScheduleController.text = profile.superOffPeakSchedule;
  }

  ElectricityCostProfile get _draftProfile {
    return ElectricityCostProfile(
      contractType: _contractType,
      monthlyConsumptionKwh: _readDouble(_monthlyConsumptionController),
      simpleTariff: _readDouble(_simpleTariffController),
      peakConsumptionKwh: _readDouble(_peakConsumptionController),
      offPeakConsumptionKwh: _readDouble(_offPeakConsumptionController),
      superOffPeakConsumptionKwh: _readDouble(
        _superOffPeakConsumptionController,
      ),
      peakTariff: _readDouble(_peakTariffController),
      offPeakTariff: _readDouble(_offPeakTariffController),
      superOffPeakTariff: _readDouble(_superOffPeakTariffController),
      peakSchedule: _peakScheduleController.text.trim(),
      offPeakSchedule: _offPeakScheduleController.text.trim(),
      superOffPeakSchedule: _superOffPeakScheduleController.text.trim(),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final profile = _draftProfile;
    final validationError = _validate(profile);
    if (validationError != null) {
      _showSnackBar(validationError);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _energyDataService.saveElectricityCostProfile(profile);
      if (!mounted) return;
      _showSnackBar('Definições de eletricidade guardadas.');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Não foi possível guardar as definições.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validate(ElectricityCostProfile profile) {
    switch (profile.contractType) {
      case ElectricityContractType.simple:
        if (profile.monthlyConsumptionKwh <= 0) {
          return 'Introduza o consumo mensal estimado.';
        }
        if (profile.simpleTariff <= 0) {
          return 'Introduza a tarifa simples em €/kWh.';
        }
        return null;
      case ElectricityContractType.biHourly:
        if (profile.totalMonthlyConsumptionKwh <= 0) {
          return 'Introduza o consumo mensal por período.';
        }
        if (profile.peakTariff <= 0 || profile.offPeakTariff <= 0) {
          return 'Introduza as tarifas de pico e fora de pico.';
        }
        return null;
      case ElectricityContractType.triHourly:
        if (profile.totalMonthlyConsumptionKwh <= 0) {
          return 'Introduza o consumo mensal por período.';
        }
        if (profile.peakTariff <= 0 ||
            profile.offPeakTariff <= 0 ||
            profile.superOffPeakTariff <= 0) {
          return 'Introduza as tarifas de todos os períodos.';
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;
    final draftProfile = _draftProfile;

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
          'Eletricidade',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildSectionTitle('Tipo de contrato'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ElectricityContractType>(
                    initialValue: _contractType,
                    decoration: _inputDecoration(),
                    items: ElectricityContractType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _contractType = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildInfoCard(
                    'Os horários ficam guardados como referência. '
                    'O cálculo usa os consumos mensais por período que definires.',
                  ),
                  const SizedBox(height: 18),
                  ..._buildContractFields(),
                  const SizedBox(height: 18),
                  _buildEstimateCard(draftProfile),
                  const SizedBox(height: 24),
                  CustomGradientButton(
                    text: _isSaving ? 'A guardar...' : 'Guardar definições',
                    gradient: myGradient,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildContractFields() {
    switch (_contractType) {
      case ElectricityContractType.simple:
        return [
          _buildSectionTitle('Dados do contrato simples'),
          const SizedBox(height: 8),
          _buildNumberField(
            controller: _monthlyConsumptionController,
            label: 'Consumo mensal estimado',
            hint: 'Ex: 250',
            suffix: 'kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _simpleTariffController,
            label: 'Tarifa',
            hint: 'Ex: 0,21',
            suffix: '€/kWh',
          ),
        ];
      case ElectricityContractType.biHourly:
        return [
          _buildSectionTitle('Consumos por período'),
          const SizedBox(height: 8),
          _buildNumberField(
            controller: _peakConsumptionController,
            label: 'Consumo durante o pico',
            hint: 'Ex: 120',
            suffix: 'kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _offPeakConsumptionController,
            label: 'Consumo fora do pico',
            hint: 'Ex: 180',
            suffix: 'kWh',
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Tarifas'),
          const SizedBox(height: 8),
          _buildNumberField(
            controller: _peakTariffController,
            label: 'Tarifa pico',
            hint: 'Ex: 0,24',
            suffix: '€/kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _offPeakTariffController,
            label: 'Tarifa fora do pico',
            hint: 'Ex: 0,16',
            suffix: '€/kWh',
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Horários'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _peakScheduleController,
            label: 'Horário de pico',
            hint: 'Ex: 09:00-12:00, 18:00-22:00',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _offPeakScheduleController,
            label: 'Horário fora do pico',
            hint: 'Ex: 22:00-09:00, 12:00-18:00',
          ),
        ];
      case ElectricityContractType.triHourly:
        return [
          _buildSectionTitle('Consumos por período'),
          const SizedBox(height: 8),
          _buildNumberField(
            controller: _peakConsumptionController,
            label: 'Consumo no pico',
            hint: 'Ex: 90',
            suffix: 'kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _offPeakConsumptionController,
            label: 'Consumo fora do pico',
            hint: 'Ex: 110',
            suffix: 'kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _superOffPeakConsumptionController,
            label: 'Consumo super fora do pico',
            hint: 'Ex: 140',
            suffix: 'kWh',
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Tarifas'),
          const SizedBox(height: 8),
          _buildNumberField(
            controller: _peakTariffController,
            label: 'Tarifa pico',
            hint: 'Ex: 0,25',
            suffix: '€/kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _offPeakTariffController,
            label: 'Tarifa fora do pico',
            hint: 'Ex: 0,19',
            suffix: '€/kWh',
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _superOffPeakTariffController,
            label: 'Tarifa super fora do pico',
            hint: 'Ex: 0,13',
            suffix: '€/kWh',
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Horários'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _peakScheduleController,
            label: 'Horário pico',
            hint: 'Ex: 10:00-12:00, 19:00-22:00',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _offPeakScheduleController,
            label: 'Horário fora do pico',
            hint: 'Ex: 08:00-10:00, 12:00-19:00',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _superOffPeakScheduleController,
            label: 'Horário super fora do pico',
            hint: 'Ex: 22:00-08:00',
          ),
        ];
    }
  }

  Widget _buildEstimateCard(ElectricityCostProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7D9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custo estimado',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C5E93),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.estimatedCostEur.toStringAsFixed(2)} € / mês',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEstimateMetric(
                  'Contrato',
                  profile.contractType.label,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildEstimateMetric(
                  'Consumo total',
                  '${profile.totalMonthlyConsumptionKwh.toStringAsFixed(1)} kWh',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateMetric(String label, String value) {
    return Container(
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
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C86A2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFF45627F),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
  }) {
    return _buildTextField(
      controller: controller,
      label: label,
      hint: hint,
      suffix: suffix,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration(hint: hint, suffix: suffix),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4E6FB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4E6FB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3DA5FA), width: 1.5),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  double _readDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  String _formatInput(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
