// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test1/services/registration_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  final _registrationService = RegistrationService();

  int? _memberId;
  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1; // 1 - форма, 2 - ввод кода

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _registrationService.createMember(
        account: _accountController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _memberId = response.memberId;

      // Запрашиваем SMS
      await _registrationService.requestSms(_memberId!);

      setState(() {
        _step = 2;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      setState(() => _errorMessage = 'Введите код из SMS');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _registrationService.verifyCode(
        _memberId!,
        _codeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация успешна! Теперь вы можете войти.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1D1D),
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 1 ? _buildForm() : _buildCodeInput(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.app_registration,
            size: 80,
            color: Color(0xFF7B0D8F),
          ),
          const SizedBox(height: 24),
          const Text(
            'Создание аккаунта',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _accountController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Логин'),
            validator: (v) => v?.isEmpty == true ? 'Введите логин' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Имя'),
            validator: (v) => v?.isEmpty == true ? 'Введите имя' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Фамилия (необязательно)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Телефон'),
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Введите телефон' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Пароль'),
            validator: (v) => v?.isEmpty == true ? 'Введите пароль' : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _createMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B0D8F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.sms,
          size: 80,
          color: Color(0xFF7B0D8F),
        ),
        const SizedBox(height: 24),
        const Text(
          'Подтверждение номера',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'На номер ${_phoneController.text} отправлен код подтверждения. Введите его ниже.',
          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _codeController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Код из SMS'),
          keyboardType: TextInputType.number,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B0D8F),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Подтвердить', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            if (_memberId != null) {
              try {
                await _registrationService.requestSms(_memberId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Код отправлен повторно')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            }
          },
          child: const Text(
            'Отправить код повторно',
            style: TextStyle(color: Color(0xFF4CAF50)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}