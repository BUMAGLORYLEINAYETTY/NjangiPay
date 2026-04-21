import 'package:flutter/foundation.dart';

class AppConstants {
  // Web (Chrome) uses localhost
  // Android uses your Mac's local IP
  // Replace 192.168.1.45 with YOUR IP from the server startup log
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return 'http://192.168.1.45:3000/api'; // ← replace with your IP
  }

  static const String tokenKey = 'auth_token';
  static const String userKey  = 'auth_user';
}
