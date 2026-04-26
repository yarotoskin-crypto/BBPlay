// lib/services/support_bot_service.dart
import 'package:test1/models/booking.dart';
import 'package:test1/models/cafe.dart';
import 'package:test1/services/api_service.dart';
import 'package:test1/services/gemini_service.dart';

/// Сообщение в чате
class SupportMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final BotAction? action;

  SupportMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.action,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Действие, которое бот предлагает выполнить
class BotAction {
  final BotActionType type;
  final Map<String, dynamic> params;

  BotAction({required this.type, required this.params});
}

enum BotActionType {
  navigateToBooking,
  openMap,
  callSupport,
  none,
}

/// Временные данные для процесса бронирования
class BookingRequest {
  int? cafeId;
  String? date;
  String? startTime;  // время начала бронирования
  int? duration;      // длительность в минутах

  bool get isComplete => cafeId != null && date != null && startTime != null && duration != null;
}

class SupportBotService {
  static final SupportBotService _instance = SupportBotService._internal();
  factory SupportBotService() => _instance;
  SupportBotService._internal();

  final ApiService _api = ApiService();
  final GeminiService _gemini = GeminiService();

  final List<SupportMessage> _history = [];
  List<Cafe> _cafes = [];
  PricesResponse? _prices;
  // ignore: unused_field
  StructRoomsResponse? _structRooms;

  bool _isInitialized = false;
  BookingRequest? _pendingBooking;
  Map<String, dynamic>? _pendingBookingParams;

  // Доступные длительности (минуты)
  static const List<int> allowedDurations = [30, 60, 120, 180, 240, 300];

  List<SupportMessage> get history => List.unmodifiable(_history);

  void setPendingBookingParams(Map<String, dynamic> params) {
    _pendingBookingParams = params;
  }

  Map<String, dynamic>? consumePendingBookingParams() {
    final params = _pendingBookingParams;
    _pendingBookingParams = null;
    return params;
  }

  /// Инициализация: загружаем данные о клубах
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _cafes = await _api.getCafes();
      if (_cafes.isNotEmpty) {
        final firstCafe = _cafes.first;
        _prices = await _api.getPrices(cafeId: firstCafe.icafeId);
        _structRooms = await _api.getStructRooms(firstCafe.icafeId);
      }
    } catch (e) {
      print('SupportBotService init error: $e');
    }
    _isInitialized = true;
  }

  SupportMessage getWelcomeMessage() {
    return SupportMessage(
      text: '👋 Привет! Я — виртуальный помощник BBPlay.\n\n'
          'Я могу:\n'
          '• Показать цены (напишите "цены")\n'
          '• Помочь с бронированием (напишите "забронировать")\n\n'
          '⚠️ Для бронирования отвечайте на мои вопросы по порядку: клуб, дата, время начала, длительность.\n'
          'Не пишите всё сразу — я буду задавать вопросы по одному.',
      isUser: false,
    );
  }

  void clearHistory() {
    _history.clear();
    _pendingBooking = null;
    _history.add(getWelcomeMessage());
  }

  Future<SupportMessage> sendUserMessage(String text) async {
    final userMsg = SupportMessage(text: text, isUser: true);
    _history.add(userMsg);

    final lower = text.toLowerCase();

    // Обработка команды "цены"
    if (lower.contains('цен') && !lower.contains('забронировать')) {
      final response = _getPricesMessage();
      final botMsg = SupportMessage(text: response, isUser: false);
      _history.add(botMsg);
      return botMsg;
    }

    // Проверяем намерение бронирования (всегда начинаем пошаговый опрос)
    if (_isBookingIntent(text)) {
      // Начинаем новый процесс бронирования
      _pendingBooking = BookingRequest();
      // Пытаемся извлечь только явные данные (клуб, дату)
      _extractBookingInfo(text);
      // Сразу переходим к первому недостающему вопросу
      return await _askForMissingInfo();
    }

    // Если активен процесс бронирования, но сообщение не содержит явного намерения,
    // обрабатываем как ответ на уточнение
    if (_pendingBooking != null) {
      return await _handleBookingFlow(text);
    }

    // Обычный ответ через Gemini
    final context = _buildContext();
    final responseText = await _gemini.sendMessageWithContext(text, context);
    final botMsg = SupportMessage(text: responseText, isUser: false);
    _history.add(botMsg);
    return botMsg;
  }

  bool _isBookingIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('забронировать') ||
        lower.contains('бронь') ||
        lower.contains('хочу забронировать') ||
        lower.contains('забронируй');
  }

  String _getPricesMessage() {
    if (_prices == null) {
      return 'Информация о ценах временно недоступна. Попробуйте позже.';
    }
    final buffer = StringBuffer();
    buffer.writeln('💰 Тарифы (почасовые):');
    final seenPrices = <String>{};
    for (var price in _prices!.prices) {
      if (seenPrices.add(price.name)) {
        buffer.writeln('• ${price.name}: ${price.pricePerHour} ₽/час');
      }
    }
    buffer.writeln('\n🎁 Пакеты:');
    final seenProducts = <String>{};
    for (var product in _prices!.products) {
      if (seenProducts.add(product.name)) {
        buffer.writeln('• ${product.name}: ${product.totalPrice} ₽ (${product.duration} мин)');
      }
    }
    buffer.writeln('\nДоступные длительности бронирования: ${allowedDurations.join(', ')} минут.');
    return buffer.toString();
  }

  Future<SupportMessage> _askForMissingInfo() async {
    String question;
    if (_pendingBooking!.cafeId == null) {
      final cafesList = _cafes.map((c) => '• ${c.address} (ID ${c.icafeId})').join('\n');
      question = 'В каком клубе хотите забронировать?\n$cafesList';
    } else if (_pendingBooking!.date == null) {
      question = 'На какую дату? (сегодня, завтра или ДД.ММ)';
    } else if (_pendingBooking!.startTime == null) {
      question = 'На какое время начало бронирования? (например, 15:00)';
    } else if (_pendingBooking!.duration == null) {
      question = 'На сколько минут/часов? Доступные длительности: ${allowedDurations.join(', ')} минут.';
    } else {
      question = 'Что-то пошло не так. Давайте попробуем ещё раз.';
    }
    final botMsg = SupportMessage(text: question, isUser: false);
    _history.add(botMsg);
    return botMsg;
  }

  Future<SupportMessage> _handleBookingFlow(String text) async {
    final lower = text.toLowerCase();
    
    if (lower.contains('отмена') || lower.contains('отменить') || lower.contains('стоп')) {
      _pendingBooking = null;
      final cancelMsg = SupportMessage(text: 'Бронирование отменено. Чем ещё могу помочь?', isUser: false);
      _history.add(cancelMsg);
      return cancelMsg;
    }

    final hadCafe = _pendingBooking!.cafeId != null;
    final hadDate = _pendingBooking!.date != null;
    final hadTime = _pendingBooking!.startTime != null;
    final hadDuration = _pendingBooking!.duration != null;

    // Извлекаем только те данные, которые сейчас запрашиваются
    if (_pendingBooking!.cafeId == null) {
      _extractCafe(text);
    } else if (_pendingBooking!.date == null) {
      _extractDate(text);
    } else if (_pendingBooking!.startTime == null) {
      _extractTime(text);
    } else if (_pendingBooking!.duration == null) {
      _extractDuration(text);
    }

    final gotNewInfo = (hadCafe != (_pendingBooking!.cafeId != null)) ||
                       (hadDate != (_pendingBooking!.date != null)) ||
                       (hadTime != (_pendingBooking!.startTime != null)) ||
                       (hadDuration != (_pendingBooking!.duration != null));

    if (!gotNewInfo) {
      String hint;
      if (_pendingBooking!.cafeId == null) {
        hint = 'Пожалуйста, укажите название или ID клуба.';
      } else if (_pendingBooking!.date == null) {
        hint = 'Введите дату в формате ДД.ММ или словами "сегодня"/"завтра".';
      } else if (_pendingBooking!.startTime == null) {
        hint = 'Укажите время начала, например "15:00".';
      } else {
        hint = 'Укажите длительность в минутах или часах. Доступные длительности: ${allowedDurations.join(', ')} минут.';
      }
      final botMsg = SupportMessage(text: hint, isUser: false);
      _history.add(botMsg);
      return botMsg;
    }

    // Проверяем длительность на соответствие тарифам
    if (_pendingBooking!.duration != null && !allowedDurations.contains(_pendingBooking!.duration)) {
      final suggested = _findClosestDurations(_pendingBooking!.duration!);
      final suggestStr = suggested.map((d) => '$d мин').join(' или ');
      final botMsg = SupportMessage(
        text: 'Длительность ${_pendingBooking!.duration} минут недоступна. Выберите из доступных: $suggestStr.',
        isUser: false,
      );
      _history.add(botMsg);
      _pendingBooking!.duration = null; // сбросим, чтобы переспросить
      return botMsg;
    }

    if (_pendingBooking!.isComplete) {
      return await _completeBooking();
    } else {
      return await _askForMissingInfo();
    }
  }

  List<int> _findClosestDurations(int value) {
    final sorted = allowedDurations.toList()..sort();
    int? closest;
    int minDiff = 9999;
    for (var d in sorted) {
      final diff = (d - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = d;
      }
    }
    final result = <int>[];
    if (closest != null) result.add(closest);
    final index = sorted.indexOf(closest!);
    if (index > 0) result.add(sorted[index - 1]);
    if (index < sorted.length - 1) result.add(sorted[index + 1]);
    return result.toSet().take(2).toList();
  }

  Future<SupportMessage> _completeBooking() async {
    final action = BotAction(
      type: BotActionType.navigateToBooking,
      params: {
        'cafeId': _pendingBooking!.cafeId,
        'date': _pendingBooking!.date,
        'time': _pendingBooking!.startTime,
        'duration': _pendingBooking!.duration,
      },
    );
    final confirmMsg = '✅ Отлично! Бронирую для клуба ID ${_pendingBooking!.cafeId} '
        'на ${_pendingBooking!.date} в ${_pendingBooking!.startTime} '
        'на ${_pendingBooking!.duration} минут.';
    final botMsg = SupportMessage(text: confirmMsg, isUser: false, action: action);
    _history.add(botMsg);
    _pendingBooking = null;
    return botMsg;
  }

  // ---------- Методы извлечения отдельных полей ----------
  void _extractCafe(String text) {
    final lower = text.toLowerCase();
    final idMatch = RegExp(r'клуб[а]?\s*(\d+)').firstMatch(lower);
    if (idMatch != null) {
      final id = int.tryParse(idMatch.group(1)!);
      if (id != null && _cafes.any((c) => c.icafeId == id)) {
        _pendingBooking!.cafeId = id;
      }
    } else {
      for (var cafe in _cafes) {
        final addressLower = cafe.address.toLowerCase();
        if (lower.contains(addressLower) || addressLower.contains(lower)) {
          _pendingBooking!.cafeId = cafe.icafeId;
          break;
        }
      }
    }
  }

  void _extractDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    if (lower.contains('сегодня')) {
      _pendingBooking!.date = _formatDate(now);
    } else if (lower.contains('завтра')) {
      final tomorrow = now.add(const Duration(days: 1));
      _pendingBooking!.date = _formatDate(tomorrow);
    } else {
      final dateReg = RegExp(r'(\d{1,2})[./](\d{1,2})');
      final match = dateReg.firstMatch(text);
      if (match != null) {
        final day = match.group(1)!.padLeft(2, '0');
        final month = match.group(2)!.padLeft(2, '0');
        _pendingBooking!.date = '${now.year}-$month-$day';
      }
    }
  }

  void _extractTime(String text) {
    final lower = text.toLowerCase();
    final timeReg = RegExp(r'(\d{1,2})[:.]?(\d{2})?');
    final match = timeReg.firstMatch(lower);
    if (match != null) {
      final hour = match.group(1)!.padLeft(2, '0');
      final minute = match.group(2) ?? '00';
      _pendingBooking!.startTime = '$hour:$minute';
    }
  }

  void _extractDuration(String text) {
    final lower = text.toLowerCase();
    final durReg = RegExp(r'на\s+(\d+)\s*(час|часов|ч|минут|мин)');
    final durMatch = durReg.firstMatch(lower);
    if (durMatch != null) {
      final value = int.tryParse(durMatch.group(1)!) ?? 60;
      final unit = durMatch.group(2)!;
      _pendingBooking!.duration = (unit.contains('час') || unit == 'ч') ? value * 60 : value;
    } else {
      final minReg = RegExp(r'(\d+)\s*минут');
      final minMatch = minReg.firstMatch(lower);
      if (minMatch != null) {
        _pendingBooking!.duration = int.tryParse(minMatch.group(1)!);
      }
    }
  }

  // Общий метод извлечения (используется только при старте для клуба и даты)
  void _extractBookingInfo(String text) {
    _extractCafe(text);
    _extractDate(text);
    // Время и длительность не извлекаем — будем спрашивать
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _buildContext() {
    final buffer = StringBuffer();
    buffer.writeln('Клубы BBPlay:');
    for (var cafe in _cafes) {
      buffer.writeln('- ${cafe.address} (ID ${cafe.icafeId})');
    }
    if (_prices != null) {
      buffer.writeln('\nТарифы (почасовые):');
      final seen = <String>{};
      for (var p in _prices!.prices) {
        if (seen.add(p.name)) {
          buffer.writeln('  ${p.name}: ${p.pricePerHour} ₽/час');
        }
      }
      buffer.writeln('Пакеты:');
      seen.clear();
      for (var p in _prices!.products) {
        if (seen.add(p.name)) {
          buffer.writeln('  ${p.name}: ${p.totalPrice} ₽ (${p.duration} мин)');
        }
      }
    }
    buffer.writeln('\nКонтакты: +7 (4752) 55-85-52');
    return buffer.toString();
  }
}