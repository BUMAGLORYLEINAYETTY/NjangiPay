import 'package:dio/dio.dart';
import '../models/transaction_model.dart';
import '../models/summary_model.dart';
import 'api_client.dart';

class TransactionService {
  static Future<SummaryModel?> getSummary() async {
    try {
      final response = await ApiClient.dio.get('/transactions/summary');
      return SummaryModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> contribute({
    required String groupId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await ApiClient.dio.post('/transactions/contribute', data: {
        'groupId': groupId,
        'amount': amount,
        'note': note,
      });
      final tx = TransactionModel.fromJson(response.data['data']);
      return {'success': true, 'transaction': tx};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Contribution failed'};
    }
  }

  static Future<List<TransactionModel>> getMyTransactions({int page = 1}) async {
    try {
      final response = await ApiClient.dio.get('/transactions', queryParameters: {'page': page});
      final list = response.data['data']['transactions'] as List;
      return list.map((t) => TransactionModel.fromJson(t)).toList();
    } catch (_) {
      return [];
    }
  }
}
