import 'package:dio/dio.dart';
import '../models/group_model.dart';
import 'api_client.dart';

class GroupService {
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    required double contributionAmt,
    required String frequency,
    required int maxMembers,
    required String startDate,
  }) async {
    try {
      final response = await ApiClient.dio.post('/groups', data: {
        'name': name,
        'description': description,
        'contributionAmt': contributionAmt,
        'frequency': frequency,
        'maxMembers': maxMembers,
        'startDate': startDate,
      });
      final group = GroupModel.fromJson(response.data['data']);
      return {'success': true, 'group': group};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to create group'};
    }
  }

  static Future<List<GroupModel>> getMyGroups() async {
    try {
      final response = await ApiClient.dio.get('/groups');
      final list = response.data['data'] as List;
      return list.map((g) => GroupModel.fromJson(g)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getGroupById(String id) async {
    try {
      final response = await ApiClient.dio.get('/groups/$id');
      final data = response.data['data'];
      return {
        'success': true,
        'group': GroupDetailModel.fromJson(data),
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to fetch group'};
    }
  }

  static Future<Map<String, dynamic>> joinByInviteCode(String code) async {
    try {
      final response = await ApiClient.dio.post('/groups/join-by-code', data: {
        'inviteCode': code.trim().toUpperCase(),
      });
      final group = GroupModel.fromJson(response.data['data']['group']);
      return {'success': true, 'group': group};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to join group'};
    }
  }

  static Future<Map<String, dynamic>> activateGroup(String id) async {
    try {
      await ApiClient.dio.patch('/groups/$id/activate');
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to activate group'};
    }
  }
}
