// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test1/services/auth_service.dart';
import 'package:test1/services/api_service.dart';
import 'package:test1/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credentials = await _authService.getCredentials();
      if (credentials == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Не найдены учётные данные';
          _isLoading = false;
        });
        return;
      }

      final user = await _authService.login(
        credentials['username']!,
        credentials['password']!,
      );
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Выход', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Вы действительно хотите выйти из аккаунта?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B0D8F)),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _topUpBalance() async {
    final user = _user ?? _authService.currentUser;
    if (user == null) {
      _showError('Пользователь не авторизован');
      return;
    }

    final amountController = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Пополнение баланса', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountController,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Сумма (₽)',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              Navigator.pop(context, amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() => _isLoading = true);
      try {
        final cafeId = await _apiService.getMemberCafeId(user.memberId);
        final data = await _apiService.topUpBalance(
          cafeId: cafeId,
          memberId: user.memberId,
          amount: result,
        );
        if (!mounted) return;
        final newBalance = data['member_balance'] ?? 'обновлён';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Баланс пополнен! Новый баланс: $newBalance ₽'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        await _loadProfile();
      } catch (e) {
        _showError('Ошибка пополнения: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('Изменить $field', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Новое значение',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      setState(() => _isLoading = true);
      try {
        final user = _user ?? _authService.currentUser;
        if (user == null) throw Exception('Пользователь не авторизован');

        final cafeId = await _apiService.getMemberCafeId(user.memberId);

        String? phone, email;
        if (field == 'телефон') {
          phone = result;
        } else if (field == 'email') {
          email = result;
        } else {
          // Для имени пока не реализовано
          _showError('Редактирование имени временно недоступно');
          setState(() => _isLoading = false);
          return;
        }

        await _apiService.updateMemberProfile(
          cafeId: cafeId,
          memberId: user.memberId,
          phone: phone,
          email: email,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные обновлены'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        await _loadProfile();
      } catch (e) {
        _showError('Ошибка обновления: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: const Color(0xFF4CAF50),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B0D8F)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('Повторить'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF4CAF50))),
              child: const Text('Войти заново', style: TextStyle(color: Color(0xFF4CAF50))),
            ),
          ],
        ),
      );
    }

    final user = _user ?? _authService.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Не авторизован', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('Войти'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _editField('имя', '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
            child: _buildAvatar(user),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _editField('имя', '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
            child: Column(
              children: [
                Text(
                  user.firstName != null && user.firstName!.isNotEmpty
                      ? '${user.firstName} ${user.lastName ?? ''}'.trim()
                      : user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '@${user.username}',
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${user.memberId}',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildInfoCardWithAction(
            label: 'Баланс',
            value: '${user.balance ?? '0'} ₽',
            icon: Icons.account_balance_wallet,
            actionIcon: Icons.add_circle_outline,
            onAction: _topUpBalance,
          ),
          const SizedBox(height: 12),

          _buildInfoCard('Бонусы', '${user.bonusBalance ?? '0'} ₽', Icons.card_giftcard),
          const SizedBox(height: 12),

          _buildInfoCardWithAction(
            label: 'Телефон',
            value: user.phone ?? 'не указан',
            icon: Icons.phone,
            actionIcon: Icons.edit,
            onAction: () => _editField('телефон', user.phone ?? ''),
          ),
          const SizedBox(height: 12),

          _buildInfoCardWithAction(
            label: 'Email',
            value: user.email ?? 'не указан',
            icon: Icons.email,
            actionIcon: Icons.edit,
            onAction: () => _editField('email', user.email ?? ''),
          ),

          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(0xFF7B0D8F)),
            label: const Text('Выйти', style: TextStyle(color: Color(0xFF7B0D8F))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF7B0D8F)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final photoUrl = user.photo;
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : const AssetImage('assets/images/logo.png') as ImageProvider,
        onBackgroundImageError: (_, __) {},
        child: (photoUrl == null || photoUrl.isEmpty) ? null : const SizedBox(),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardWithAction({
    required String label,
    required String value,
    required IconData icon,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(actionIcon, color: const Color(0xFF4CAF50)),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}