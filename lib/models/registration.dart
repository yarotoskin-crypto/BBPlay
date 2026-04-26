// lib/models/registration.dart
class RegistrationResponse {
  final int code;
  final String message;
  final Map<String, dynamic>? data;

  RegistrationResponse({required this.code, required this.message, this.data});

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      code: json['code'],
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class CreateMemberResponse {
  final int memberId;
  final String memberAccount;

  CreateMemberResponse({required this.memberId, required this.memberAccount});

  factory CreateMemberResponse.fromJson(Map<String, dynamic> json) {
    return CreateMemberResponse(
      memberId: json['member_id'],
      memberAccount: json['member_account'] ?? '',
    );
  }
}