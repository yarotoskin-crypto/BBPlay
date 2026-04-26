// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test1/screens/news_screen.dart';
import 'package:test1/screens/clubs_screen.dart';
import 'package:test1/screens/booking_screen.dart';
import 'package:test1/screens/support_screen.dart';
import 'package:test1/screens/profile_screen.dart';
import 'package:test1/screens/login_screen.dart';
import 'package:test1/screens/register_screen.dart';
import 'package:test1/services/auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/news',
  redirect: (context, state) async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    final path = state.uri.path;

    if (path == '/login' || path == '/register') {
      if (isLoggedIn) return '/news';
      return null;
    }

    if (!isLoggedIn) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return const ScaffoldWithBottomNavBar();
      },
      routes: [
        GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
        GoRoute(path: '/clubs', builder: (context, state) => const ClubsScreen()),
GoRoute(
  path: '/booking',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return BookingScreen(
      initialCafeId: extra?['cafeId'] as int?,
      initialDate: extra?['date'] as String?,
      initialTime: extra?['time'] as String?,
      initialDuration: extra?['duration'] as int?,
    );
  },
),
        GoRoute(
  path: '/support',
  builder: (context, state) => const SupportScreen(),
),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);

class ScaffoldWithBottomNavBar extends StatefulWidget {
  const ScaffoldWithBottomNavBar({super.key});

  @override
  State<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<ScaffoldWithBottomNavBar> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<String> _routes = [
    '/news',
    '/clubs',
    '/booking',
    '/support',
    '/profile',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPageFromRoute();
  }

  void _syncPageFromRoute() {
    if (!mounted) return;
    final location = GoRouterState.of(context).uri.path;
    final newIndex = _routes.indexOf(location);
    if (newIndex != -1 && newIndex != _currentIndex) {
      _currentIndex = newIndex;
      _pageController.jumpToPage(newIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      context.go(_routes[index]);
    }
  }

  void _onBottomTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Новости';
      case 1: return 'Клубы';
      case 2: return 'Бронирование';
      case 3: return 'Поддержка';
      case 4: return 'Профиль';
      default: return 'BBPlay';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_currentIndex)),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          NewsScreen(),
          ClubsScreen(),
          BookingScreen(), // initialCafeId передаётся через параметр конструктора, но здесь он не нужен
          SupportScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomTap,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1D1D1D),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Клубы'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Бронирование'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Поддержка'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}