import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiUrl {
    // 1. Try dart-define (ideal for Vercel/CI)
    const defineUrl = String.fromEnvironment('API_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    // 2. Try dotenv (for local/existing setup)
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // 3. Fallback
    return 'http://localhost:5000/api';
  }
}
