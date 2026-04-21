import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import '../models/escrow_model.dart';
import '../models/trust_model.dart';
import 'api_client.dart';

class PaymentService {
  static Future<Map<String, dynamic>> initiatePayment({
    required String groupId,
    required double amount,
    required String method,
    required String phone,
    String? note,
  }) async {
    try {
      final response = await ApiClient.dio.post('/payments/initiate', data: {
        'groupId': groupId,
        'amount': amount,
        'method': method,
        'phone': phone,
        'note': note,
      });
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Payment failed'};
    }
  }

  static Future<Map<String, dynamic>> confirmPayment(String reference) async {
    try {
      final response = await ApiClient.dio.post('/payments/confirm', data: {'reference': reference});
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Confirmation failed'};
    }
  }

  static Future<List<PaymentModel>> getPaymentHistory({String? groupId}) async {
    try {
      final params = <String, dynamic>{};
      if (groupId != null) params['groupId'] = groupId;
      final response = await ApiClient.dio.get('/payments/history', queryParameters: params);
      final list = response.data['data']['payments'] as List;
      return list.map((p) => PaymentModel.fromJson(p)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> savePaymentMethod({
    required String method,
    required String phone,
    bool isDefault = false,
  }) async {
    try {
      final response = await ApiClient.dio.post('/payments/methods', data: {
        'method': method, 'phone': phone, 'isDefault': isDefault,
      });
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to save method'};
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedMethods() async {
    try {
      final response = await ApiClient.dio.get('/payments/methods');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> enableAutoPay({
    required String groupId,
    required int dayOfMonth,
    required String method,
    required String phone,
  }) async {
    try {
      final response = await ApiClient.dio.post('/payments/auto-pay/enable', data: {
        'groupId': groupId, 'dayOfMonth': dayOfMonth, 'method': method, 'phone': phone,
      });
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed'};
    }
  }

  static Future<Map<String, dynamic>> generateQRCode(String groupId) async {
    try {
      final response = await ApiClient.dio.post('/payments/qr/generate', data: {'groupId': groupId});
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed'};
    }
  }

  // ESCROW
  static Future<Map<String, dynamic>> getEscrowBalance() async {
    try {
      final response = await ApiClient.dio.get('/escrow/balance');
      final data = response.data['data'];
      return {
        'success': true,
        'totalHeld': data['totalHeld'],
        'escrows': (data['escrows'] as List).map((e) => EscrowModel.fromJson(e)).toList(),
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed'};
    }
  }

  static Future<Map<String, dynamic>> requestEarlyRelease(String escrowId) async {
    try {
      final response = await ApiClient.dio.post('/escrow/release-request', data: {'escrowId': escrowId});
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed'};
    }
  }

  // TRUST
  static Future<TrustScoreModel?> getTrustScore() async {
    try {
      final response = await ApiClient.dio.get('/trust/score');
      return TrustScoreModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiClient.dio.get('/trust/notifications');
      final list = response.data['data']['notifications'] as List;
      return list.map((n) => NotificationModel.fromJson(n)).toList();
    } catch (_) {
      return [];
    }
  }
}
