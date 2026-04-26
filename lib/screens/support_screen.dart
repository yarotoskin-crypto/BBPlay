// lib/screens/support_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test1/services/support_bot_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportBotService _botService = SupportBotService();
  
  bool _isInitializing = true;
  bool _isTyping = false;
  
  late AnimationController _dotAnimationController;

  @override
  void initState() {
    super.initState();
    _dotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initialize();
  }

  Future<void> _initialize() async {
    await _botService.initialize();
    if (!mounted) return;
    if (_botService.history.isEmpty) {
      _botService.clearHistory(); // добавит приветствие
    }
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>?;
    final message = extra?['message'] as String?;
    if (message != null && message.isNotEmpty) {
      _controller.text = message;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() => _isTyping = true);
    _scrollToBottom();

    final response = await _botService.sendUserMessage(text);

    if (!mounted) return;
    
    setState(() => _isTyping = false);
    
    if (response.action != null) {
      _handleAction(response.action!);
    }
    
    _scrollToBottom();
  }

void _handleAction(BotAction action) {
  switch (action.type) {
    case BotActionType.navigateToBooking:
      // Сохраняем параметры в сервисе перед переходом
      _botService.setPendingBookingParams(action.params);
      context.go('/booking');
      break;
    default:
      break;
  }
}

  void _newChat() {
    setState(() {
      _botService.clearHistory();
      _isTyping = false;
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B0D8F)),
      );
    }
    
    final messages = _botService.history;
    
    return Column(
      children: [
        // Заголовок чата
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade800,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF7B0D8F),
                child: Icon(Icons.support_agent, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Поддержка BBPlay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Онлайн • отвечаем быстро',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF7B0D8F)),
                tooltip: 'Новый чат',
                onPressed: _newChat,
              ),
            ],
          ),
        ),

        // Список сообщений
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == messages.length) {
                return _buildTypingIndicator();
              }
              final msg = messages[index];
              return _buildMessageBubble(msg);
            },
          ),
        ),

        // Поле ввода
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade800,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Напишите сообщение...',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF7B0D8F),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? const Color(0xFF7B0D8F) 
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: message.isUser ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            if (message.action != null && message.action!.type != BotActionType.none)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () => _handleAction(message.action!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('Перейти к бронированию'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _dotAnimationController,
          builder: (context, child) {
            final opacity1 = 0.3 + 0.7 * (_dotAnimationController.value % 0.333) * 3;
            final opacity2 = 0.3 + 0.7 * ((_dotAnimationController.value + 0.333) % 0.333) * 3;
            final opacity3 = 0.3 + 0.7 * ((_dotAnimationController.value + 0.666) % 0.333) * 3;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF9E9E9E).withOpacity(opacity1), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF9E9E9E).withOpacity(opacity2), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF9E9E9E).withOpacity(opacity3), shape: BoxShape.circle)),
              ],
            );
          },
        ),
      ),
    );
  }
}