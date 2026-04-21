import 'transaction_model.dart';

class SummaryModel {
  final double totalContributed;
  final double totalReceived;
  final int activeGroups;
  final List<TransactionModel> recentTransactions;

  SummaryModel({
    required this.totalContributed,
    required this.totalReceived,
    required this.activeGroups,
    required this.recentTransactions,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      totalContributed: (json['totalContributed'] as num).toDouble(),
      totalReceived: (json['totalReceived'] as num).toDouble(),
      activeGroups: json['activeGroups'],
      recentTransactions: (json['recentTransactions'] as List)
          .map((t) => TransactionModel.fromJson(t))
          .toList(),
    );
  }
}
