// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:test1/services/club_data_service.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBXf-IYXrI-695D1t5riO0i3jv84DZORoo';
  
  late final GenerativeModel _model;
  final ClubDataService _dataService = ClubDataService();
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview', // обновлённая модель
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
      systemInstruction: Content.text(
        'Ты — администратор компьютерного клуба BBPlay. '
        'Отвечай кратко, дружелюбно и по делу. '
        'Используй ТОЛЬКО ту информацию, которая передана тебе в контексте. '
        'Не придумывай цены, адреса или другие данные, если их нет в контексте.',
      ),
    );
  }

  /// Формирует контекст с актуальными данными клуба (старый метод, оставлен для совместимости)
  String _buildContext() {
    return '''
АКТУАЛЬНАЯ ИНФОРМАЦИЯ О КЛУБЕ:

${_dataService.getAvailabilityInfo()}

${_dataService.getPricesInfo()}

${_dataService.getEquipmentInfo()}

Контакты:
Адрес: ${_dataService.contacts['address']}
Телефон: ${_dataService.contacts['phone']}
Telegram: ${_dataService.contacts['telegram']}
Discord: ${_dataService.contacts['discord']}
Режим работы: ${_dataService.contacts['work_hours']}

ВАЖНО: Отвечай на основе ЭТИХ данных. Не выдумывай другую информацию.
''';
  }

  Future<String> sendMessage(String message) async {
    try {
      final fullPrompt = '''
${_buildContext()}

ВОПРОС ПОСЕТИТЕЛЯ: $message

ОТВЕТ (краткий, дружелюбный, только на основе данных выше):
''';
      
      final content = Content.text(fullPrompt);
      final response = await _model.generateContent([content]);
      return response.text ?? 'Извините, я не смог сформулировать ответ.';
    } catch (e) {
      return 'Ошибка связи с поддержкой. Попробуйте позже.\nОшибка: $e';
    }
  }

  /// Новый метод: отправка сообщения с пользовательским контекстом
  Future<String> sendMessageWithContext(String message, String context) async {
    try {
      final fullPrompt = '''
$context

ВОПРОС ПОСЕТИТЕЛЯ: $message

ОТВЕТ (краткий, дружелюбный, только на основе данных выше):
''';
      final content = Content.text(fullPrompt);
      final response = await _model.generateContent([content]);
      return response.text ?? 'Извините, я не смог сформулировать ответ.';
    } catch (e) {
      return 'Ошибка связи с поддержкой. Попробуйте позже.\nОшибка: $e';
    }
  }
}