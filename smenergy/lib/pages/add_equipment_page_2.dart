import 'package:flutter/material.dart';
import 'package:smenergy/pages/add_equipment_page_3.dart';

class SetupStepOnePage extends StatelessWidget {
  const SetupStepOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Alinhamento do "1/2" próximo à seta conforme o design
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
              "1/2",
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

            // LISTA DE INSTRUÇÕES
            const Text(
              '1. Ligar Equipamento à tomada\n'
              '2. Ligar WiFi 2.4 GHz do telemóvel\n'
              '3. Selecionar a Rede de Equipamento',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.8, // Espaçamento entre linhas
              ),
            ),

            const SizedBox(height: 40),

            // CAIXA DE SELECÇÃO WIFI (O CARD DO PRINT)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
              ),
              child: Column(
                children: [
                  // Cabeçalho da caixa (Barra azul clara)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.blue.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'WiFi',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item da Rede (Onde o utilizador clica)
                  ListTile(
                    title: const Text(
                      'SMEnergy_AP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.wifi,
                      color: Colors.black,
                      size: 20,
                    ),
                    onTap: () {
                      // NAVEGAÇÃO PARA O PASSO 2/2
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SetupStepTwoPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
