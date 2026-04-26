// lib/services/club_data_service.dart
//import 'package:flutter/material.dart';

/// Модель данных для одного клуба
class Club {
  final String id;
  final String name;
  final String address;
  final String? description;
  final String? phone;
  final String? workingHours;
  final String? imageUrl;
  final List<String>? features;
  final Map<String, dynamic>? additionalInfo;

  Club({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.phone,
    this.workingHours,
    this.imageUrl,
    this.features,
    this.additionalInfo,
  });
}

class ClubDataService {
  static final ClubDataService _instance = ClubDataService._internal();
  factory ClubDataService() => _instance;
  ClubDataService._internal();

  // ---------- ДАННЫЕ КЛУБОВ ----------
  List<Club> getClubs() {
    return [
      Club(
        id: 'sovetskaya',
        name: 'BBPlay на Советской',
        address: 'ул. Советская, 121',
        description: 'Основной клуб сети. Мощные ПК, PlayStation 5, лаунж-зона.',
        phone: '+7 (4752) 55-85-52',
        workingHours: 'Круглосуточно',
        imageUrl: 'assets/images/sov.png',   // ← путь к картинке
        features: ['🎮 RTX 4070', '🖥️ 240 Гц', '🎧 HyperX', '🕹️ PS5'],
        additionalInfo: {
          'total_pcs': 25,
          'vip_zone': true,
          'parking': 'Есть',
        },
      ),
      Club(
        id: 'astrakhanskaya',
        name: 'BBPlay на Астраханской',
        address: 'ул. Астраханская, 2В',
        description: 'Уютный клуб в центре города. Новое оборудование, отдельные VIP-комнаты.',
        phone: '+7 (4752) 55-85-53',
        workingHours: 'Круглосуточно',
        imageUrl: 'assets/images/astr.png', // ← путь к картинке
        features: ['🎮 RTX 4060 Ti', '🖥️ 165 Гц', '🎧 Razer', '🎱 Зона отдыха'],
        additionalInfo: {
          'total_pcs': 18,
          'vip_zone': true,
          'parking': 'По записи',
        },
      ),
    ];
  }

  // ---------- ОСТАЛЬНЫЕ ДАННЫЕ (ЦЕНЫ, БРОНИРОВАНИЯ) ----------
  // ... (ваш текущий код цен, контактов и бронирований остается здесь) ...
  final Map<String, int> prices = {
    'standard': 150,
    'vip': 300,
    'console': 250,
    'night_package': 800,
  };

  final Map<String, String> contacts = {
    'address': 'г. Тамбов, ул. Советская, 121',
    'phone': '+7 (4752) 55-85-52',
    'telegram': '@bbplay_tmb',
    'discord': 'discord.gg/bbplay',
    'work_hours': 'Круглосуточно, без выходных',
  };

   String getAvailabilityInfo() {
    final clubs = getClubs();
    final info = StringBuffer();
    for (var club in clubs) {
      final total = club.additionalInfo?['total_pcs'] as int? ?? 0;
      // Поскольку бронирования пока не реализованы, считаем все места свободными
      info.writeln('${club.name}: свободно $total из $total ПК');
    }
    return info.toString();
  }

  /// Возвращает информацию о ценах
  String getPricesInfo() {
    return '''
Наши цены (единые для всех клубов):
💻 Стандарт — ${prices['standard']} ₽/час
👑 VIP-зона — ${prices['vip']} ₽/час
🕹️ Консоль — ${prices['console']} ₽/час
🌙 Ночной пакет (23:00–08:00) — ${prices['night_package']} ₽
''';
  }

  /// Возвращает информацию об оборудовании
  String getEquipmentInfo() {
    return '''
Наше железо:
💻 Стандарт: RTX 4070, Intel i7-13700K, 32 ГБ RAM, 240 Гц
👑 VIP: RTX 4090, Intel i9-13900K, 64 ГБ RAM, 4K 144 Гц
🕹️ Консоли: PlayStation 5, Xbox Series X
''';
  }
}