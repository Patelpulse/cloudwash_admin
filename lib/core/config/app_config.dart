import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const bool isTesting = true; // Set to false to use the live URL

  static String get apiUrl {
    // Override with custom environment variable if provided
    const defineUrl = String.fromEnvironment('API_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    if (isTesting) {
      return 'http://localhost:5001/api';
    } else {
      return 'http://72.61.172.182:5006/api';
    }
  }
}
