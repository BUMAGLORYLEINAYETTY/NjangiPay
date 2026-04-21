import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // ── WRITE ──────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
    } else {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    }
  }

  static Future<void> saveUser(UserModel user) async {
    final data = jsonEncode(user.toJson());
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, data);
    } else {
      await _storage.write(key: AppConstants.userKey, value: data);
    }
  }

  // ── READ ───────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    }
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<UserModel?> getUser() async {
    try {
      String? data;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        data = prefs.getString(AppConstants.userKey);
      } else {
        data = await _storage.read(key: AppConstants.userKey);
      }
      if (data == null) return null;
      return UserModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userKey);
    } else {
      await _storage.deleteAll();
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
