import 'package:flutter/material.dart';
import 'package:test1/widgets/booking_tab.dart';
import 'package:test1/widgets/games_tab.dart';
import 'package:test1/widgets/my_bookings_tab.dart';
import 'package:test1/services/support_bot_service.dart';

class BookingScreen extends StatefulWidget {
  final int? initialCafeId;
  final String? initialDate;
  final String? initialTime;
  final int? initialDuration;

  const BookingScreen({
    super.key,
    this.initialCafeId,
    this.initialDate,
    this.initialTime,
    this.initialDuration,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
    late final TabController _tabController;
  int? _cafeId;
  String? _date;
  String? _time;
  int? _duration;

   @override
  void initState() {
    super.initState();
    // Получаем сохранённые параметры бронирования
    final params = SupportBotService().consumePendingBookingParams();
    if (params != null) {
      _cafeId = params['cafeId'];
      _date = params['date'];
      _time = params['time'];
      _duration = params['duration'];
    }
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: const Color(0xFF4CAF50),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Забронировать', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Мои бронирования', icon: Icon(Icons.list_alt)),
            Tab(text: 'Мини-игры', icon: Icon(Icons.videogame_asset)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              BookingTab(
    initialCafeId: _cafeId,
    initialDate: _date,
    initialTime: _time,
    initialDuration: _duration,
  ),
              const MyBookingsTab(),
              const GamesTab(),
            ],
          ),
        ),
      ],
    );
  }
}