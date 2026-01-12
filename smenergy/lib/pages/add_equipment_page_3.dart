import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page_4.dart';
import 'package:smenergy/pages/dashboard_page.dart';
import 'package:smenergy/services/config_service.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class SetupStepTwoPage extends StatefulWidget {
  const SetupStepTwoPage({super.key});

  @override
  State<SetupStepTwoPage> createState() => _SetupStepTwoPageState();
}

class _SetupStepTwoPageState extends State<SetupStepTwoPage> {
  bool _isObscure = true;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              "2/2",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Configuração Equipamento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              '4. Conecte-se a uma rede Wi-Fi',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // INPUT SSID
            CustomPopOutInput(
              controller:
                  _ssidController, // Passando o controller para capturar o texto
              icon: Icons.wifi,
              hint: 'SSID',
              gradient: myGradient,
            ),

            const SizedBox(height: 20),

            // INPUT PASSWORD
            CustomPopOutInput(
              controller: _passController, // Passando o controller
              icon: Icons.wifi_lock_rounded,
              hint: 'Password',
              gradient: myGradient,
              isPassword: true,
              isObscure: _isObscure,
              onToggleVisibility: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),

            const SizedBox(height: 420),

            CustomGradientButton(
              text: 'Conectar',
              gradient: myGradient,
              onPressed: () async {
                // 1. Grava que está configurado (Produção)
                await ConfigService.setConfigStatus(1);

                // (Impede o utilizador de voltar ao setup com o botão 'back')
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardPage(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
