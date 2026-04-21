class PaymentModel {
  final String id;
  final String groupId;
  final double amount;
  final String method;
  final String phone;
  final String status;
  final String reference;
  final double platformFee;
  final double insuranceFee;
  final double netAmount;
  final int cycleNumber;
  final String? note;
  final DateTime? paidAt;
  final DateTime createdAt;
  final Map<String, dynamic>? group;

  PaymentModel({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.method,
    required this.phone,
    required this.status,
    required this.reference,
    required this.platformFee,
    required this.insuranceFee,
    required this.netAmount,
    required this.cycleNumber,
    this.note,
    this.paidAt,
    required this.createdAt,
    this.group,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      groupId: json['groupId'],
      amount: (json['amount'] as num).toDouble(),
      method: json['method'],
      phone: json['phone'],
      status: json['status'],
      reference: json['reference'],
      platformFee: (json['platformFee'] as num).toDouble(),
      insuranceFee: (json['insuranceFee'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      cycleNumber: json['cycleNumber'] ?? 1,
      note: json['note'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      group: json['group'],
    );
  }

  String get methodLabel => method == 'MTN_MOMO' ? 'MTN Mobile Money' : 'Orange Money';
  bool get isSuccess => status == 'SUCCESS';
}
