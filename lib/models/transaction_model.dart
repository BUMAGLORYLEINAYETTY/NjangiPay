class TransactionModel {
  final String id;
  final String userId;
  final String groupId;
  final double amount;
  final String type;
  final String status;
  final String reference;
  final String? note;
  final DateTime createdAt;
  final Map<String, dynamic>? group;
  final Map<String, dynamic>? user;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.type,
    required this.status,
    required this.reference,
    this.note,
    required this.createdAt,
    this.group,
    this.user,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      groupId: json['groupId'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      status: json['status'],
      reference: json['reference'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      group: json['group'],
      user: json['user'],
    );
  }

  bool get isDebit => type == 'CONTRIBUTION';
}
