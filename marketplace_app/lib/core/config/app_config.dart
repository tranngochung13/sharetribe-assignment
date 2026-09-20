import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String apiBaseUrl = 'https://flex-api.sharetribe.com';

  static String get clientId =>
      dotenv.env['SHARETRIBE_CLIENT_ID'] ?? '';
}