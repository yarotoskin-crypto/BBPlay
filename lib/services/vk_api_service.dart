import 'dart:convert';
import 'package:http/http.dart' as http;

class VkApiService {
  // Замените на ваш сервисный ключ
  static const String _serviceToken = '9f5d7b579f5d7b579f5d7b57c39c1d555399f5d9f5d7b57f68753c5c5e761c3ba003c56';
  static const String _apiVersion = '5.131';

  /// Получает записи со стены сообщества.
  Future<List<dynamic>> fetchWallPosts({
    required int ownerId,
    int count = 20,
    int offset = 0,
  }) async {
    // Для сообщества owner_id должен быть отрицательным
    final url = Uri.parse(
      'https://api.vk.com/method/wall.get'
      '?owner_id=-$ownerId'
      '&count=$count'
      '&offset=$offset'
      '&access_token=$_serviceToken'
      '&v=$_apiVersion',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('VK API Error: ${data['error']['error_msg']}');
      }
      return data['response']['items'] as List<dynamic>;
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }
}