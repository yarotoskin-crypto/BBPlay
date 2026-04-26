class User {
  final String memberId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? balance;
  final String? bonusBalance;
  final String? points;
  final String? phone;
  final String? email;
  final String? birthday;
  final String? photo;
  final String? token;
  final String? privateKey;
  final String? cafeId; // новое

  User({
    required this.memberId,
    required this.username,
    this.firstName,
    this.lastName,
    this.balance,
    this.bonusBalance,
    this.points,
    this.phone,
    this.email,
    this.birthday,
    this.photo,
    this.token,
    this.privateKey,
    this.cafeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      memberId: json['member_id'].toString(),
      username: json['member_account'] ?? '',
      firstName: json['member_first_name'],
      lastName: json['member_last_name'],
      balance: json['member_balance']?.toString(),
      bonusBalance: json['member_balance_bonus']?.toString(),
      points: json['member_points']?.toString(),
      phone: json['member_phone'],
      email: json['member_email'],
      birthday: json['member_birthday'],
      photo: json['member_photo'],
      token: json['token'],
      privateKey: json['private_key'],
      cafeId: json['member_icafe_id']?.toString(),
    );
  }
}