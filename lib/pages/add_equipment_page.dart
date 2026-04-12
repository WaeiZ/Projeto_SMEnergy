import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page_2.dart';
import 'package:smenergy/widgets/custom_widgets.dart';

class AddEquipmentPage extends StatelessWidget {
  const AddEquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myGradient = AppGradients.blueLinear;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Image.asset('assets/logo.png', height: 180, fit: BoxFit.contain),

              const SizedBox(height: 60),

              // TEXTO
              const Text(
                'Adicionar Equipamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // BOTÃO CIRCULAR "+"
              GestureDetector(
                onTap: () {
                  // Navega para o Passo 1/2
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupStepOnePage(),
                    ),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF3DA5FA),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => myGradient.createShader(bounds),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 50,
                      color: Colors.white, // O ShaderMask vai pintar o ícone
                    ),
                  ),
                ),
              ),

              // Espaço extra no fundo para equilibrar o centro visual
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
