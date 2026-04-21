class EscrowModel {
  final String id;
  final String groupId;
  final double totalHeld;
  final double amountReleased;
  final double remainingHeld;
  final List<ReleaseSlot> releaseSchedule;
  final String status;
  final int cycleWon;
  final int trustScoreAtWin;
  final double winnerPayout;
  final DateTime createdAt;
  final Map<String, dynamic>? group;

  EscrowModel({
    required this.id,
    required this.groupId,
    required this.totalHeld,
    required this.amountReleased,
    required this.remainingHeld,
    required this.releaseSchedule,
    required this.status,
    required this.cycleWon,
    required this.trustScoreAtWin,
    required this.winnerPayout,
    required this.createdAt,
    this.group,
  });

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['releaseSchedule'] as List? ?? [];
    return EscrowModel(
      id: json['id'],
      groupId: json['groupId'],
      totalHeld: (json['totalHeld'] as num).toDouble(),
      amountReleased: (json['amountReleased'] as num).toDouble(),
      remainingHeld: (json['remainingHeld'] as num).toDouble(),
      releaseSchedule: rawSchedule.map((s) => ReleaseSlot.fromJson(s)).toList(),
      status: json['status'],
      cycleWon: json['cycleWon'],
      trustScoreAtWin: json['trustScoreAtWin'],
      winnerPayout: (json['winnerPayout'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      group: json['group'],
    );
  }
}

class ReleaseSlot {
  final int cycleNumber;
  final double amount;
  final bool released;

  ReleaseSlot({required this.cycleNumber, required this.amount, required this.released});

  factory ReleaseSlot.fromJson(Map<String, dynamic> json) {
    return ReleaseSlot(
      cycleNumber: json['cycleNumber'],
      amount: (json['amount'] as num).toDouble(),
      released: json['released'] ?? false,
    );
  }
}
