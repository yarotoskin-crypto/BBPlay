import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test1/models/booking.dart';
import 'package:test1/models/cafe.dart';

class ApiService {
  static const String _baseUrl = 'https://vibe.blackbearsplay.ru';
  static const int _defaultCafeId = 87375; // ID клуба по умолчанию (Медвежья)

  // ---------- Получение списка клубов ----------
  Future<List<Cafe>> getCafes() async {
    final url = Uri.parse('$_baseUrl/cafes');
    print('📡 GET $url');
    final response = await http.get(url);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        final List cafesJson = data['data'];
        return cafesJson.map((json) => Cafe.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Ошибка загрузки клубов');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Структура зала ----------
  Future<StructRoomsResponse> getStructRooms(int cafeId) async {
    final uri = Uri.parse('$_baseUrl/struct-rooms-icafe')
        .replace(queryParameters: {'cafeId': cafeId.toString()});
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        return StructRoomsResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Ошибка загрузки структуры зала');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Доступные ПК ----------
  Future<AvailablePCsResponse> getAvailablePCs({
    required int cafeId,
    required String dateStart,
    required String timeStart,
    required int mins,
    bool isFindWindow = true,
    String? priceName,
  }) async {
    final queryParams = {
      'cafeId': cafeId.toString(),
      'dateStart': dateStart,
      'timeStart': timeStart,
      'mins': mins.toString(),
      if (isFindWindow) 'isFindWindow': 'true',
      if (priceName != null) 'priceName': priceName,
    };
    final uri = Uri.parse('$_baseUrl/available-pcs-for-booking')
        .replace(queryParameters: queryParams);
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        return AvailablePCsResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Ошибка проверки доступности');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Создание брони ----------
  Future<void> createBooking({
    required int icafeId,
    required String pcName,
    required String memberAccount,
    required int memberId,
    required String startDate,
    required String startTime,
    required int mins,
    String? privateKey,
    int? productId,
  }) async {
    final url = Uri.parse('$_baseUrl/booking');
    final randKey = (10000000000 + DateTime.now().millisecondsSinceEpoch % 90000000000).toString();

    final body = <String, dynamic>{
      'icafe_id': icafeId,
      'member_account': memberAccount,
      'member_id': memberId,
      'start_date': startDate,
      'start_time': startTime,
      'mins': mins,
      'rand_key': randKey,
      if (privateKey != null) 'key': privateKey,
    };

    if (productId != null) {
      body['product_id'] = productId;
    } else {
      body['pc_name'] = pcName;
    }

    print('📡 POST $url');
    print('📡 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final code = data['code'];
      final message = data['message'] ?? '';

      if ((code == 0 || code == 3) &&
          (message == 'Success' || message == 'Successful' || message.startsWith('Успе'))) {
        return;
      }

      String errorMsg = message;
      if (data['iCafe_response'] != null && data['iCafe_response']['message'] != null) {
        errorMsg = data['iCafe_response']['message'].toString();
      }
      throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Ошибка бронирования');
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Получение броней пользователя ----------
  Future<List<UserBooking>> getUserBookings(String memberAccount) async {
    final uri = Uri.parse('$_baseUrl/all-books-cafes')
        .replace(queryParameters: {'memberAccount': memberAccount});
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        final dynamic bookingsData = data['data'];
        List<UserBooking> allBookings = [];

        if (bookingsData is Map<String, dynamic>) {
          bookingsData.forEach((cafeIdStr, bookingsList) {
            final cafeId = int.tryParse(cafeIdStr);
            if (bookingsList is List) {
              allBookings.addAll(
                bookingsList.map((b) => UserBooking.fromJson(b, cafeId: cafeId)),
              );
            }
          });
        } else if (bookingsData is List) {
          allBookings = bookingsData.map((b) => UserBooking.fromJson(b, cafeId: null)).toList();
        }
        return allBookings;
      } else {
        throw Exception(data['message'] ?? 'Ошибка загрузки броней');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Получение цен ----------
  Future<PricesResponse> getPrices({
    required int cafeId,
    String? bookingDate,
    int? mins,
    int? memberId,
  }) async {
    final queryParams = {
      'cafeId': cafeId.toString(),
      if (bookingDate != null) 'bookingDate': bookingDate,
      if (mins != null) 'mins': mins.toString(),
      if (memberId != null) 'memberId': memberId.toString(),
    };
    final uri = Uri.parse('$_baseUrl/all-prices-icafe')
        .replace(queryParameters: queryParams);
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        return PricesResponse.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Ошибка загрузки цен');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Отмена бронирования (через /booking-cancel) ----------
  Future<void> cancelBooking({
    required String pcName,
    required String memberOfferId,
  }) async {
    final url = Uri.parse('$_baseUrl/booking-cancel');
    final body = {
      'pc_name': pcName,
      'member_offer_id': memberOfferId,
    };
    print('📡 POST (Cancel) $url');
    print('📡 Body: $body');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ожидаем code 200 или 0
      if (data['code'] != 200 && data['code'] != 0) {
        throw Exception(data['message'] ?? 'Ошибка отмены бронирования');
      }
    } else {
      throw Exception('Ошибка соединения: ${response.statusCode}');
    }
  }

  // ---------- Получение ID клуба для участника ----------
  Future<int> getMemberCafeId(String memberId) async {
    try {
      final uri = Uri.parse('$_baseUrl/icafe-id-for-member');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0 && data['data'] != null && data['data']['icafe_id'] != null) {
          return int.parse(data['data']['icafe_id'].toString());
        }
      }
    } catch (e) {
      print('⚠️ Не удалось получить cafeId участника: $e');
    }
    return _defaultCafeId; // fallback
  }

  // ---------- Получение профиля участника (через список всех участников клуба) ----------
  Future<Map<String, dynamic>> getMemberProfile({
    required int cafeId,
    required String memberId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v2/cafe/$cafeId/members');
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Код успеха может быть 200 или 0
      if (data['code'] == 200 || data['code'] == 0) {
        final members = (data['data']['members'] ?? []) as List<dynamic>;
        final member = members.firstWhere(
          (m) => m['member_id'].toString() == memberId,
          orElse: () => throw Exception('Участник с ID $memberId не найден'),
        );
        return member as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Ошибка получения списка участников');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ---------- Пополнение баланса (исправлено выбрасывание ошибок) ----------
  Future<Map<String, dynamic>> topUpBalance({
    required int cafeId,
    required String memberId,
    required double amount,
    double? bonus,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v2/cafe/$cafeId/members/action/topup');
    final body = {
      'topup_ids': memberId,
      'topup_value': amount,
      if (bonus != null) 'topup_balance_bonus': bonus,
    };
    print('📡 POST $uri');
    print('📡 Body: $body');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Если есть сообщение об ошибке (например, "Api not allowed")
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        final code = data['code'];
        // Успешные коды: 200, 0 или отсутствие кода
        if (code != null && code != 200 && code != 0) {
          throw Exception(data['message']);
        }
        // Если кода нет, но сообщение не "Success", считаем ошибкой
        if (code == null && data['message'] != 'Success') {
          throw Exception(data['message']);
        }
      }
      // Доп. проверка по коду
      if (data['code'] != null && data['code'] != 200 && data['code'] != 0) {
        throw Exception(data['message'] ?? 'Неизвестная ошибка пополнения');
      }
      // Возвращаем данные (если есть)
      return data['data'] as Map<String, dynamic>? ?? {};
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ---------- Обновление профиля участника (исправлено выбрасывание ошибок) ----------
  Future<void> updateMemberProfile({
    required int cafeId,
    required String memberId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v2/cafe/$cafeId/members/$memberId');
    final body = <String, dynamic>{
      if (firstName != null) 'member_first_name': firstName,
      if (lastName != null) 'member_last_name': lastName,
      if (phone != null) 'member_phone': phone,
      if (email != null) 'member_email': email,
    };
    print('📡 PATCH $uri');
    print('📡 Body: $body');

    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Обработка сообщения об ошибке
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        final code = data['code'];
        if (code != null && code != 200 && code != 0) {
          throw Exception(data['message']);
        }
        if (code == null && data['message'] != 'Success') {
          throw Exception(data['message']);
        }
      }
      if (data['code'] != null && data['code'] != 200 && data['code'] != 0) {
        throw Exception(data['message'] ?? 'Ошибка обновления профиля');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // ---------- (Опционально) Получение информации по логину ----------
  Future<Map<String, dynamic>> getMemberInfoByAccount({
    required int cafeId,
    required String account,
  }) async {
    final uri = Uri.parse('$_baseUrl/member-info-by-account')
        .replace(queryParameters: {
          'cafeId': cafeId.toString(),
          'account': account,
        });
    print('📡 GET $uri');
    final response = await http.get(uri);
    print('📡 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Ошибка получения информации');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}