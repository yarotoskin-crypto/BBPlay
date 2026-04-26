// lib/screens/clubs_screen.dart
import 'package:flutter/material.dart';
import 'package:test1/models/cafe.dart';
import 'package:test1/services/api_service.dart';
import 'package:test1/services/club_actions.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final ApiService _apiService = ApiService();
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  String? _error;

  static const Map<int, String> _clubImages = {
    87375: 'assets/images/club_medvezhya.png',
  };

  @override
  void initState() {
    super.initState();
    _loadCafes();
  }

  Future<void> _loadCafes() async {
    try {
      final cafes = await _apiService.getCafes();
      if (!mounted) return;
      setState(() {
        _cafes = cafes;
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

  Widget _buildClubCard(BuildContext context, Cafe cafe, String imagePath) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 160,
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: Icon(Icons.sports_esports, size: 64, color: Color(0xFF7B0D8F)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BBPlay',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF7B0D8F), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cafe.address,
                        style: const TextStyle(
                            color: Color(0xFFBDBDBD), fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.access_time,
                        color: Color(0xFF7B0D8F), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Круглосуточно',
                      style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Компьютерный клуб премиум-класса. Мощные ПК, консоли, уютная атмосфера.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.calendar_month,
                      label: 'Бронь',
                      onPressed: () => ClubActions.bookPlace(context, cafe),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.map_outlined,
                      label: 'Карта',
                      onPressed: () => ClubActions.showMap(context, cafe),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.chat,
                      label: 'Связь',
                      onPressed: () => ClubActions.showContactOptions(context, cafe),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B0D8F)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadCafes();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_cafes.isEmpty) {
      return const Center(
        child: Text('Нет доступных клубов',
            style: TextStyle(color: Colors.white)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCafes,
      color: const Color(0xFF7B0D8F),
      backgroundColor: const Color(0xFF2A2A2A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cafes.length,
        itemBuilder: (context, index) {
          final cafe = _cafes[index];
          final imagePath = _clubImages[cafe.icafeId] ??
              'assets/images/club_placeholder.png';
          return _buildClubCard(context, cafe, imagePath);
        },
      ),
    );
  }
}