// lib/widgets/openstreetmap_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final String address;
  final LatLng point;

  const OpenStreetMapWidget({
    super.key,
    required this.address,
    this.point = const LatLng(52.721695, 41.452759), // Тамбов
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Заголовок с адресом и кнопками
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF1D1D1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser, color: Color(0xFF4CAF50)),
                    onPressed: () => _openInBrowser(),
                  ),
                ],
              ),
            ),
            // Карта
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bbplay.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: point,
                        child: GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(address)),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInBrowser() async {
    final encoded = Uri.encodeComponent(address);
    final url = 'https://yandex.ru/maps/?text=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}