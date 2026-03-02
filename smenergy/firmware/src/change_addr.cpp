#include <Arduino.h>
#include <PZEM004Tv30.h>

// Usa a Serial2 (Pinos 16 e 17)
PZEM004Tv30 pzem(Serial2, 16, 17);

// ALTERA ESTE VALOR para cada sensor (0x01, 0x02 ou 0x03)
#define NOVO_ENDERECO 0x02 

void setup() {
    Serial.begin(115200);
    Serial2.begin(9600, SERIAL_8N1, 16, 17);
    
    delay(2000);
    Serial.println("--- PROGRAMADOR DE ENDEREÇO PZEM ---");
    
    Serial.print("Endereço atual: ");
    Serial.println(pzem.getAddress(), HEX);

    Serial.print("A tentar mudar para: ");
    Serial.println(NOVO_ENDERECO, HEX);

    if(pzem.setAddress(NOVO_ENDERECO)) {
        Serial.println("SUCESSO! O endereço foi alterado.");
    } else {
        Serial.println("ERRO! Não foi possível alterar o endereço.");
        Serial.println("Verifica se o PZEM tem alimentação AC (230V).");
    }
}

void loop() {
    // Nada a fazer aqui
}