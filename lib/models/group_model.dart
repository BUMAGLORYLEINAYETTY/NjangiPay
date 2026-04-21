class GroupModel {
  final String id;
  final String name;
  final String? description;
  final double contributionAmt;
  final String frequency;
  final int maxMembers;
  final DateTime startDate;
  final String status;
  final String inviteCode;
  final DateTime createdAt;
  final int? memberCount;
  final String? myRole;
  final int currentCycle;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.contributionAmt,
    required this.frequency,
    required this.maxMembers,
    required this.startDate,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    this.memberCount,
    this.myRole,
    this.currentCycle = 1,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id:             json['id'],
      name:           json['name'],
      description:    json['description'],
      contributionAmt:(json['contributionAmt'] as num).toDouble(),
      frequency:      json['frequency'],
      maxMembers:     json['maxMembers'],
      startDate:      DateTime.parse(json['startDate']),
      status:         json['status'],
      inviteCode:     json['inviteCode'] ?? '',
      createdAt:      DateTime.parse(json['createdAt']),
      memberCount:    json['_count']?['members'],
      currentCycle:   json['currentCycle'] ?? 1,
      myRole:         json['members'] != null && (json['members'] as List).isNotEmpty
          ? json['members'][0]['role']
          : null,
    );
  }
}

class GroupMemberModel {
  final String id;
  final String userId;
  final String role;
  final int? payoutOrder;
  final DateTime joinedAt;
  final Map<String, dynamic> user;

  GroupMemberModel({
    required this.id,
    required this.userId,
    required this.role,
    this.payoutOrder,
    required this.joinedAt,
    required this.user,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id:          json['id'],
      userId:      json['userId'],
      role:        json['role'],
      payoutOrder: json['payoutOrder'],
      joinedAt:    DateTime.parse(json['joinedAt']),
      user:        json['user'],
    );
  }

  String get fullName   => user['fullName'] ?? '';
  String get email      => user['email'] ?? '';
  int    get trustScore => user['trustScore'] ?? 100;
}

class GroupDetailModel {
  final GroupModel group;
  final List<GroupMemberModel> members;
  final double escrowBalance;
  final double myContributions;

  GroupDetailModel({
    required this.group,
    required this.members,
    required this.escrowBalance,
    required this.myContributions,
  });

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailModel(
      group:           GroupModel.fromJson(json),
      members:         (json['members'] as List)
          .map((m) => GroupMemberModel.fromJson(m))
          .toList(),
      escrowBalance:   (json['escrowBalance'] as num?)?.toDouble() ?? 0,
      myContributions: (json['myContributions'] as num?)?.toDouble() ?? 0,
    );
  }
}
