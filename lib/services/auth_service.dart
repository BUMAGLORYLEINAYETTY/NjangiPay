import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      });

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user']);
      final token = data['token'];

      await StorageService.saveToken(token);
      await StorageService.saveUser(user);

      return {'success': true, 'user': user};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Registration failed',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user']);
      final token = data['token'];

      await StorageService.saveToken(token);
      await StorageService.saveUser(user);

      return {'success': true, 'user': user};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Login failed',
      };
    }
  }

  static Future<UserModel?> getMe() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    await StorageService.clearAll();
  }
}
