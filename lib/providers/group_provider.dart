import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    notifyListeners();
    _groups = await GroupService.getMyGroups();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createGroup({
    required String name,
    String? description,
    required double contributionAmt,
    required String frequency,
    required int maxMembers,
    required String startDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await GroupService.createGroup(
      name: name,
      description: description,
      contributionAmt: contributionAmt,
      frequency: frequency,
      maxMembers: maxMembers,
      startDate: startDate,
    );

    _isLoading = false;
    if (result['success']) {
      await fetchGroups();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> joinByCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await GroupService.joinByInviteCode(code);

    _isLoading = false;
    if (result['success']) {
      await fetchGroups();
      notifyListeners();
      return {
        'success': true,
        'groupName': (result['group'] as GroupModel).name,
      };
    } else {
      _error = result['message'];
      notifyListeners();
      return {'success': false, 'message': result['message']};
    }
  }
}
