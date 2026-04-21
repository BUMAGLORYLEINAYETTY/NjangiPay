class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final int trustScore;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.trustScore,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      trustScore: json['trustScore'] ?? 100,
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'trustScore': trustScore,
        'isVerified': isVerified,
        'createdAt': createdAt.toIso8601String(),
      };
}
