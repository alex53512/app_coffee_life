class EnvConfig {
  EnvConfig._();

  // ── API Backend principal ──
  static String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://backend-coffe-lifee-production-191b.up.railway.app',
      );

  // ── Chatbot / IA ──
  static String get chatbotBaseUrl => const String.fromEnvironment(
        'CHATBOT_BASE_URL',
        defaultValue: 'https://chatbot-ia-production.up.railway.app',
      );

  // ── IA (diagnóstico) ──
  static String get iaLocalBaseUrl => const String.fromEnvironment(
        'IA_LOCAL_BASE_URL',
        defaultValue: 'https://despliegue-escaner-production.up.railway.app',
      );

  // ── Escáner IA en producción ──
  static String get escanerBaseUrl => const String.fromEnvironment(
        'ESCANER_BASE_URL',
        defaultValue: 'https://despliegue-escaner-production.up.railway.app',
      );

  // ── Weather API ──
  static String get weatherApiKey => const String.fromEnvironment(
        'WEATHER_API_KEY',
        defaultValue: '27cc92d850e34ed4923194316261905',
      );

  static String get weatherApiUrl => const String.fromEnvironment(
        'WEATHER_API_URL',
        defaultValue: 'https://api.weatherapi.com/v1',
      );

  // ── CDN / Media (para imágenes) ──
  static String get cdnBaseUrl => const String.fromEnvironment(
        'CDN_BASE_URL',
        defaultValue: 'https://coffeelife-api.up.railway.app',
      );
}
