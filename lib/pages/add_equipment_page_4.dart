import 'package:flutter/material.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class SetupFinishPage extends StatelessWidget {
  const SetupFinishPage({super.key});

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
              "3/3",
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

            // Texto Centralizado
            Expanded(
              child: Center(
                child: Text(
                  'Configuração Concluída',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade400, // O azul do teu design
                  ),
                ),
              ),
            ),

            // Botão Confirmar
            CustomGradientButton(
              text: 'Confirmar',
              gradient: myGradient,
              onPressed: () {
                // Remove todas as telas de setup e volta para a Dashboard
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),

            const SizedBox(height: 30),

            // Home Indicator
            Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
