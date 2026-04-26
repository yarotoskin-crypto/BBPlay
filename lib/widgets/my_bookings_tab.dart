// lib/widgets/my_bookings_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test1/models/booking.dart';
import 'package:test1/services/api_service.dart';
import 'package:test1/services/auth_service.dart';

class MyBookingsTab extends StatefulWidget {
  const MyBookingsTab({super.key});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<UserBooking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = _authService.currentUser;
    if (user == null || user.username.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Не авторизован';
        _isLoading = false;
      });
      return;
    }
    try {
      final bookings = await _apiService.getUserBookings(user.username);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFoodMenu() {
    // ... (оставлено без изменений, как в предыдущей версии)
  }

  void _showBookingHistory() {
    // ... (оставлено без изменений)
  }

  Future<void> _handleCancel(UserBooking booking) async {
    final confirm = await _showConfirmDialog(booking);
    if (confirm != true) return;

    setState(() => _cancellingId = booking.memberOfferId);

    try {
      await _apiService.cancelBooking(
        pcName: booking.pcName,
        memberOfferId: booking.memberOfferId,
      );
      if (!mounted) return;
      _showSnackBar('✅ Бронирование отменено');
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('❌ Ошибка отмены: $e', isError: true);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  Future<bool?> _showConfirmDialog(UserBooking booking) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Отменить бронирование?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.pcName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${_formatDateTime(booking.from)} → ${_formatTime(booking.to)}',
                style: const TextStyle(color: Color(0xFFBDBDBD))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, отменить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
        ),
      );
    });
  }

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadBookings();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFoodMenu,
                  icon: const Icon(Icons.fastfood, color: Colors.white),
                  label: const Text('Заказать еду', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showBookingHistory,
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text('История', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _bookings.isEmpty
              ? const Center(child: Text('У вас пока нет бронирований', style: TextStyle(color: Colors.white70, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final isCancelling = _cancellingId == booking.memberOfferId;
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.computer, color: Color(0xFF7B0D8F)),
                        title: Text(booking.pcName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDateTime(booking.from)} → ${_formatTime(booking.to)}',
                              style: const TextStyle(color: Color(0xFFBDBDBD)),
                            ),
                            Text(
                              '${booking.mins} мин. • ${booking.description}',
                              style: const TextStyle(color: Color(0xFF9E9E9E)),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: isCancelling
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.cancel, color: Color(0xFF4CAF50)),
                                onPressed: () => _handleCancel(booking),
                                tooltip: 'Отменить бронирование',
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}