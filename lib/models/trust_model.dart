class TrustScoreModel {
  final int currentScore;
  final PayoutBreakdown payoutBreakdown;
  final int nextTier;
  final int pointsToNextTier;
  final List<TrustHistoryItem> history;
  final List<Map<String, String>> improvements;
  final List<Map<String, String>> warnings;

  TrustScoreModel({
    required this.currentScore,
    required this.payoutBreakdown,
    required this.nextTier,
    required this.pointsToNextTier,
    required this.history,
    required this.improvements,
    required this.warnings,
  });

  factory TrustScoreModel.fromJson(Map<String, dynamic> json) {
    return TrustScoreModel(
      currentScore: json['currentScore'],
      payoutBreakdown: PayoutBreakdown.fromJson(json['payoutBreakdown']),
      nextTier: json['nextTier'],
      pointsToNextTier: json['pointsToNextTier'],
      history: (json['history'] as List).map((h) => TrustHistoryItem.fromJson(h)).toList(),
      improvements: (json['improvements'] as List).map((i) => Map<String, String>.from(i)).toList(),
      warnings: (json['warnings'] as List).map((w) => Map<String, String>.from(w)).toList(),
    );
  }
}

class PayoutBreakdown {
  final int nowPercent;
  final int heldPercent;
  final int releaseCycles;

  PayoutBreakdown({required this.nowPercent, required this.heldPercent, required this.releaseCycles});

  factory PayoutBreakdown.fromJson(Map<String, dynamic> json) {
    return PayoutBreakdown(
      nowPercent: json['nowPercent'],
      heldPercent: json['heldPercent'],
      releaseCycles: json['releaseCycles'],
    );
  }
}

class TrustHistoryItem {
  final String id;
  final int change;
  final String reason;
  final String description;
  final int scoreBefore;
  final int scoreAfter;
  final DateTime createdAt;

  TrustHistoryItem({
    required this.id,
    required this.change,
    required this.reason,
    required this.description,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.createdAt,
  });

  factory TrustHistoryItem.fromJson(Map<String, dynamic> json) {
    return TrustHistoryItem(
      id: json['id'],
      change: json['change'],
      reason: json['reason'],
      description: json['description'],
      scoreBefore: json['scoreBefore'],
      scoreAfter: json['scoreAfter'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  bool get isPositive => change > 0;
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime sentAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      isRead: json['isRead'] ?? false,
      sentAt: DateTime.parse(json['sentAt']),
    );
  }
}
