// lib/services/club_actions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:test1/models/cafe.dart';
import 'package:test1/widgets/openstreetmap_widget.dart';

class ClubActions {
  static void bookPlace(BuildContext context, Cafe cafe) {
    context.go('/booking', extra: {'cafeId': cafe.icafeId});
  }

  static void showMap(BuildContext context, Cafe cafe) {
    showDialog(
      context: context,
      builder: (context) => OpenStreetMapWidget(address: cafe.address),
    );
  }


  static void showContactOptions(BuildContext context, Cafe cafe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                title: const Text('Позвонить', style: TextStyle(color: Colors.white)),
                subtitle: const Text('+7 (4752) 55-85-52', style: TextStyle(color: Color(0xFFBDBDBD))),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('tel:+74752558552');
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF4CAF50)),
                title: const Text('Написать на почту', style: TextStyle(color: Colors.white)),
                subtitle: const Text('contact@bbplay.ru', style: TextStyle(color: Color(0xFFBDBDBD))),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('mailto:contact@bbplay.ru');
                },
              ),
              ListTile(
                leading: const Icon(Icons.telegram, color: Color(0xFF4CAF50)),
                title: const Text('Telegram', style: TextStyle(color: Colors.white)),
                subtitle: const Text('@bbplay_tmb', style: TextStyle(color: Color(0xFFBDBDBD))),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('https://t.me/bbplay_tmb');
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Color(0xFF4CAF50)),
                title: const Text('Поддержка', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  final message = 'Здравствуйте, пишу по поводу клуба на ${cafe.address}';
                  context.go('/support', extra: {'message': message});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}