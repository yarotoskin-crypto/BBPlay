import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadUserFromStorage();
  }

  static const String _baseUrl = 'https://vibe.blackbearsplay.ru';
  static const String _memberIdKey = 'member_id';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _privateKeyKey = 'private_key';
  static const String _cafeIdKey = 'member_icafe_id';

  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString(_memberIdKey);
    final username = prefs.getString(_usernameKey) ?? '';
    final privateKey = prefs.getString(_privateKeyKey);
    if (memberId != null && memberId.isNotEmpty) {
      _currentUser = User(
        memberId: memberId,
        username: username,
        privateKey: privateKey,
      );
    }
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser == null) await _loadUserFromStorage();
    return _currentUser != null;
  }

  Future<User> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final client = http.Client();
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_name': username,
          'password': password,
        }),
      );

      print('📡 Login response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 3 && data['member'] != null) {
          final memberData = data['member'] as Map<String, dynamic>;
          final privateKey = data['private_key'] as String?;
          var user = User.fromJson(memberData);
          if (privateKey != null) {
            user = User(
              memberId: user.memberId,
              username: user.username,
              firstName: user.firstName,
              lastName: user.lastName,
              balance: user.balance,
              bonusBalance: user.bonusBalance,
              points: user.points,
              phone: user.phone,
              email: user.email,
              birthday: user.birthday,
              photo: user.photo,
              token: user.token,
              privateKey: privateKey,
              cafeId: memberData['member_icafe_id']?.toString(), // <-- сохраняем cafeId
            );
          }
          await _saveUserData(user, password);
          _currentUser = user;
          print('🎉 Login success: ${user.memberId}');
          return user;
        }

        if (data['code'] == 0 && data['message'] != null) {
          throw Exception(data['message']);
        }

        throw Exception('Неизвестный ответ сервера');
      } else {
        throw Exception('Ошибка соединения: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memberIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_privateKeyKey);
    await prefs.remove(_cafeIdKey);
    _currentUser = null;
  }

  Future<void> _saveUserData(User user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memberIdKey, user.memberId);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_passwordKey, password);
    if (user.privateKey != null) {
      await prefs.setString(_privateKeyKey, user.privateKey!);
    }
    if (user.cafeId != null) {
      await prefs.setString(_cafeIdKey, user.cafeId!);
    }
  }

  Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final password = prefs.getString(_passwordKey);
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<String?> getCafeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cafeIdKey);
  }
}