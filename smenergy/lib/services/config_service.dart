import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _key = 'is_configured_flag';

  // MODO DEBUG: Se esta variável for diferente de null,
  // a app ignora o que está gravado e usa este valor.
  // Coloca 1 para Dashboard, 0 para Setup, ou null para usar a memória real.
  static int? debugOverride = null;

  // Recupera o estado (0 ou 1)
  static Future<int> getConfigStatus() async {
    if (debugOverride != null) return debugOverride!;

    final prefs = await SharedPreferences.getInstance();
    // Se for a primeira vez (null), retorna 0 (não configurado)
    return prefs.getInt(_key) ?? 0;
  }

  // Grava o estado
  static Future<void> setConfigStatus(int status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, status);
  }

  // Limpa tudo (útil para testes)
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
