// lib/widgets/games_tab.dart
import 'package:flutter/material.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  void _openGame(String gameId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        switch (gameId) {
          case 'guess':
            return const GuessNumberGameModal();
          case 'rps':
            return const RockPaperScissorsGameModal();
          case 'tictactoe':
            return const TicTacToeGameModal();
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        _buildGameCard(
          title: 'Угадай число',
          subtitle: 'Компьютер загадал число от 1 до 100',
          icon: Icons.casino,
          onTap: () => _openGame('guess'),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          title: 'Камень, ножницы, бумага',
          subtitle: 'Сыграйте против компьютера',
          icon: Icons.sports_handball,
          onTap: () => _openGame('rps'),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          title: 'Крестики-нолики',
          subtitle: 'Для двух игроков на одном устройстве',
          icon: Icons.grid_3x3,
          onTap: () => _openGame('tictactoe'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 2), // зелёная обводка
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 36),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        ),
        trailing: const Icon(Icons.play_arrow, color: Color(0xFF4CAF50), size: 32),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

// ------------------ Модалка "Угадай число" ------------------
class GuessNumberGameModal extends StatefulWidget {
  const GuessNumberGameModal({super.key});

  @override
  State<GuessNumberGameModal> createState() => _GuessNumberGameModalState();
}

class _GuessNumberGameModalState extends State<GuessNumberGameModal> {
  late int _secretNumber;
  final TextEditingController _controller = TextEditingController();
  String _message = 'Введите число от 1 до 100';
  int _attempts = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _secretNumber = 1 + (DateTime.now().millisecondsSinceEpoch % 100);
    _attempts = 0;
    _gameOver = false;
    _message = 'Введите число от 1 до 100';
    _controller.clear();
    setState(() {});
  }

  void _checkGuess() {
    if (_gameOver) return;
    final guess = int.tryParse(_controller.text);
    if (guess == null || guess < 1 || guess > 100) {
      setState(() => _message = 'Некорректный ввод. Введите число от 1 до 100');
      return;
    }
    setState(() {
      _attempts++;
      if (guess < _secretNumber) {
        _message = '📈 Загаданное число БОЛЬШЕ';
      } else if (guess > _secretNumber) {
        _message = '📉 Загаданное число МЕНЬШЕ';
      } else {
        _message = '🎉 Поздравляем! Вы угадали за $_attempts попыток.';
        _gameOver = true;
      }
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Угадай число',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
                    onPressed: _resetGame,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ваше число',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            enabled: !_gameOver,
          ),
          const SizedBox(height: 20),
          if (_gameOver)
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Новая игра', style: TextStyle(fontSize: 18)),
            )
          else
            ElevatedButton(
              onPressed: _checkGuess,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Проверить', style: TextStyle(fontSize: 18)),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ------------------ Модалка "Камень, ножницы, бумага" ------------------
class RockPaperScissorsGameModal extends StatefulWidget {
  const RockPaperScissorsGameModal({super.key});

  @override
  State<RockPaperScissorsGameModal> createState() => _RockPaperScissorsGameModalState();
}

class _RockPaperScissorsGameModalState extends State<RockPaperScissorsGameModal> {
  String _result = 'Сделайте выбор';
  String? _playerChoice;
  String? _computerChoice;

  final Map<String, IconData> _icons = {
    'rock': Icons.circle,
    'paper': Icons.description,
    'scissors': Icons.cut,
  };

  final Map<String, String> _translations = {
    'rock': 'Камень',
    'paper': 'Бумага',
    'scissors': 'Ножницы',
  };

  void _play(String playerChoice) {
    final options = ['rock', 'paper', 'scissors'];
    final computerChoice = options[DateTime.now().millisecondsSinceEpoch % 3];
    String result;
    if (playerChoice == computerChoice) {
      result = 'Ничья!';
    } else if ((playerChoice == 'rock' && computerChoice == 'scissors') ||
               (playerChoice == 'paper' && computerChoice == 'rock') ||
               (playerChoice == 'scissors' && computerChoice == 'paper')) {
      result = '🎉 Вы выиграли!';
    } else {
      result = '💻 Компьютер выиграл!';
    }
    setState(() {
      _playerChoice = playerChoice;
      _computerChoice = computerChoice;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Камень, ножницы, бумага',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _result,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChoiceDisplay('Вы', _playerChoice),
              const SizedBox(width: 40),
              _buildChoiceDisplay('Компьютер', _computerChoice),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Сделайте выбор:',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChoiceButton('rock'),
              const SizedBox(width: 20),
              _buildChoiceButton('paper'),
              const SizedBox(width: 20),
              _buildChoiceButton('scissors'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(String choice) {
    return ElevatedButton(
      onPressed: () => _play(choice),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A2A2A),
        padding: const EdgeInsets.all(20),
        shape: const CircleBorder(),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      child: Icon(_icons[choice], size: 40, color: const Color(0xFF4CAF50)),
    );
  }

  Widget _buildChoiceDisplay(String label, String? choice) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
          ),
          child: choice == null
              ? null
              : Icon(_icons[choice], size: 50, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          choice != null ? _translations[choice]! : '',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

// ------------------ Модалка "Крестики-нолики" ------------------
class TicTacToeGameModal extends StatefulWidget {
  const TicTacToeGameModal({super.key});

  @override
  State<TicTacToeGameModal> createState() => _TicTacToeGameModalState();
}

class _TicTacToeGameModalState extends State<TicTacToeGameModal> {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String _status = 'Ход игрока X';

  void _makeMove(int index) {
    if (_board[index] != '' || _checkWinner() != null) return;

    setState(() {
      _board[index] = _currentPlayer;
      final winner = _checkWinner();
      if (winner != null) {
        _status = winner == 'draw' ? 'Ничья!' : 'Победил игрок $winner!';
      } else {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        _status = 'Ход игрока $_currentPlayer';
      }
    });
  }

  String? _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (var line in lines) {
      if (_board[line[0]] != '' &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[0]] == _board[line[2]]) {
        return _board[line[0]];
      }
    }
    if (!_board.contains('')) return 'draw';
    return null;
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _status = 'Ход игрока X';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Крестики-нолики',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
                    onPressed: _resetGame,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _status,
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _makeMove(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A), // просто серый квадрат, без обводки
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _board[index],
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: _board[index] == 'X' ? const Color(0xFF4CAF50) : const Color(0xFF7B0D8F),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          if (_checkWinner() != null)
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Новая игра', style: TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );
  }
}