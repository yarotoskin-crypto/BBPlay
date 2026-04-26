// lib/services/registration_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test1/models/registration.dart';

class RegistrationService {
  static const String _baseUrl = 'https://vibe.blackbearsplay.ru';
  static const int _cafeId = 87375;

  Future<CreateMemberResponse> createMember({
    required String account,
    required String firstName,
    required String phone,
    String? lastName,
    String? password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v2/cafe/$_cafeId/members');
    final client = http.Client();
    try {
      final body = {
        'member_account': account,
        'member_first_name': firstName,
        'member_phone': phone,
        if (lastName != null && lastName.isNotEmpty) 'member_last_name': lastName,
        if (password != null && password.isNotEmpty) 'member_password': password,
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📡 Create member response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['code'].toString();
        if ((code == '0' || code == '201') && data['data'] != null) {
          return CreateMemberResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Ошибка создания аккаунта');
        }
      } else {
        throw Exception('Ошибка соединения: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> requestSms(int memberId) async {
    final url = Uri.parse('$_baseUrl/request-sms');
    final client = http.Client();
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'member_id': memberId}),
      );

      print('📡 Request SMS response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['code'].toString();
        if (code != '0' && code != '201') {
          throw Exception(data['message'] ?? 'Ошибка отправки SMS');
        }
      } else {
        throw Exception('Ошибка соединения: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> verifyCode(int memberId, String code) async {
  final url = Uri.parse('$_baseUrl/verify');
  final client = http.Client();
  try {
    final body = <String, dynamic>{
      'member_id': memberId,
    };
    if (code.isNotEmpty) {
      body['code'] = code;
    }

    print('📡 Verify request body: $body');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('📡 Verify response status: ${response.statusCode}');
    print('📡 Verify response body: ${response.body}');

    if (response.statusCode == 200) {
      // Если тело пустое или состоит из пробелов — считаем успехом
      if (response.body.trim().isEmpty) {
        return; // успех
      }
      final data = jsonDecode(response.body);
      final respCode = data['code'].toString();
      if (respCode != '0' && respCode != '201') {
        throw Exception(data['message'] ?? 'Ошибка верификации');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
}