// lib/widgets/booking_map_widget.dart
import 'package:flutter/material.dart';
import 'package:test1/models/booking.dart';
import 'package:test1/services/api_service.dart';

class BookingMapWidget extends StatefulWidget {
  final int cafeId;
  final PricesResponse? pricesResponse;
  final bool Function(PC pc) isPcAvailable;
  final void Function(PC pc) onPcTap;
  final void Function(Product product) onPackageTap;
  final void Function(String message) showMessage;
  final bool isDateTimeSelected;

  const BookingMapWidget({
    super.key,
    required this.cafeId,
    required this.pricesResponse,
    required this.isPcAvailable,
    required this.onPcTap,
    required this.onPackageTap,
    required this.showMessage,
    required this.isDateTimeSelected,
  });

  static const double pcDisplaySize = 40.0;
  static const double roomNameFontSize = 16.0;
  static const double pcNameFontSize = 11.0;
  static const double mapPadding = 40.0;

  @override
  State<BookingMapWidget> createState() => _BookingMapWidgetState();
}

class _BookingMapWidgetState extends State<BookingMapWidget> {
  final ApiService _apiService = ApiService();
  StructRoomsResponse? _structRooms;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStructRooms();
  }

  Future<void> _loadStructRooms() async {
    try {
      final struct = await _apiService.getStructRooms(widget.cafeId);
      if (!mounted) return;
      setState(() {
        _structRooms = struct;
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

  void _showPackagesList() {
    if (!widget.isDateTimeSelected) {
      widget.showMessage('Сначала выберите дату и время');
      return;
    }

    final products = widget.pricesResponse?.products ?? [];
    if (products.isEmpty) {
      widget.showMessage('Нет доступных пакетов');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Доступные пакеты',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isAvailable = _isPackageAvailable(product);
                    return Card(
                      color: const Color(0xFF1D1D1D),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isAvailable
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF7B0D8F),
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          product.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          isAvailable
                              ? '${product.totalPrice} ₽ • ${product.isCalcDuration ? 'от ${product.durationMin}' : product.duration} мин.'
                              : 'Недоступен',
                          style: TextStyle(
                            color: isAvailable
                                ? const Color(0xFFBDBDBD)
                                : Colors.redAccent,
                          ),
                        ),
                        trailing: isAvailable
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onPackageTap(product);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                                child: const Text('Забронировать'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isPackageAvailable(Product product) {
    if (!widget.isDateTimeSelected) return true;
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      TimeOfDay.now().hour,
      TimeOfDay.now().minute,
    );
    if (product.showTimeStart.isNotEmpty && product.showTimeEnd.isNotEmpty) {
      final startParts = product.showTimeStart.split(':');
      final endParts = product.showTimeEnd.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        final selectedMinutes = selectedDateTime.hour * 60 + selectedDateTime.minute;
        if (selectedMinutes < startMinutes || selectedMinutes > endMinutes) {
          return false;
        }
      }
    }
    return true;
  }

  Room _applyHardcodedCorrections(Room room) {
    double newWidth = room.areaFrameWidth;
    double newHeight = room.areaFrameHeight;
    double newX = room.areaFrameX;
    double newY = room.areaFrameY;
    List<PC> newPcs = room.pcs;

    if (room.areaName == 'GameZone') {
      newWidth = room.areaFrameWidth * 1.0;
      newHeight = room.areaFrameHeight * 1.0;
    } else if (room.areaName == 'VIP') {
      newX = room.areaFrameX + 150;
      newPcs = room.pcs.map((pc) {
        return PC(
          name: pc.name,
          areaName: pc.areaName,
          isUsing: pc.isUsing,
          startDate: pc.startDate,
          startTime: pc.startTime,
          endDate: pc.endDate,
          endTime: pc.endTime,
          groupName: pc.groupName,
          priceName: pc.priceName,
          enabled: pc.enabled,
          pcBoxLeft: pc.pcBoxLeft - 60,
          pcBoxTop: pc.pcBoxTop,
          pcBoxPosition: pc.pcBoxPosition,
          pcComment: pc.pcComment,
          pcConsoleType: pc.pcConsoleType,
          pcIcafeId: pc.pcIcafeId,
        );
      }).toList();
    }

    return Room(
      areaIcafeId: room.areaIcafeId,
      areaName: room.areaName,
      colorBorder: room.colorBorder,
      colorText: room.colorText,
      pcs: newPcs,
      areaIndex: room.areaIndex,
      areaFrameX: newX,
      areaFrameY: newY,
      areaFrameWidth: newWidth,
      areaFrameHeight: newHeight,
      areaAllowBooking: room.areaAllowBooking,
      allowPayByRoom: room.allowPayByRoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B0D8F)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки карты: $_error',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadStructRooms();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_structRooms == null || _structRooms!.rooms.isEmpty) {
      return const Center(
          child: Text('Нет данных для отображения карты',
              style: TextStyle(color: Colors.white)));
    }

    final rooms = _structRooms!.rooms.map((r) => _applyHardcodedCorrections(r)).toList();

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (var room in rooms) {
      final roomRight = room.areaFrameX + room.areaFrameWidth;
      final roomBottom = room.areaFrameY + room.areaFrameHeight;
      minX = minX < room.areaFrameX ? minX : room.areaFrameX;
      minY = minY < room.areaFrameY ? minY : room.areaFrameY;
      maxX = maxX > roomRight ? maxX : roomRight;
      maxY = maxY > roomBottom ? maxY : roomBottom;

      for (var pc in room.pcs) {
        final pcLeft = room.areaFrameX + pc.pcBoxLeft;
        final pcTop = room.areaFrameY + pc.pcBoxTop;
        minX = minX < pcLeft ? minX : pcLeft;
        minY = minY < pcTop ? minY : pcTop;
        maxX = maxX > pcLeft + BookingMapWidget.pcDisplaySize ? maxX : pcLeft + BookingMapWidget.pcDisplaySize;
        maxY = maxY > pcTop + BookingMapWidget.pcDisplaySize ? maxY : pcTop + BookingMapWidget.pcDisplaySize;
      }
    }

    final totalWidth = maxX - minX + 2 * BookingMapWidget.mapPadding;
    final totalHeight = maxY - minY + 2 * BookingMapWidget.mapPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / totalWidth;
        final scaleY = constraints.maxHeight / totalHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        return Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: Container(
                width: totalWidth * scale,
                height: totalHeight * scale,
                color: const Color(0xFF1D1D1D),
                child: CustomPaint(
                  painter: _MapPainter(
                    rooms: rooms,
                    minX: minX,
                    minY: minY,
                    padding: BookingMapWidget.mapPadding,
                    scale: scale,
                    isPcAvailable: widget.isPcAvailable,
                  ),
                  child: _MapGestureDetector(
                    rooms: rooms,
                    minX: minX,
                    minY: minY,
                    padding: BookingMapWidget.mapPadding,
                    scale: scale,
                    onPcTap: (pc) {
                      if (!widget.isDateTimeSelected) {
                        widget.showMessage('Сначала выберите дату и время');
                        return;
                      }
                      widget.onPcTap(pc);
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: ElevatedButton.icon(
                onPressed: _showPackagesList,
                icon: const Icon(Icons.card_giftcard, size: 20),
                label: const Text('Пакеты'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<Room> rooms;
  final double minX;
  final double minY;
  final double padding;
  final double scale;
  final bool Function(PC pc) isPcAvailable;

  _MapPainter({
    required this.rooms,
    required this.minX,
    required this.minY,
    required this.padding,
    required this.scale,
    required this.isPcAvailable,
  });

  static Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF7B0D8F);
    final buffer = StringBuffer();
    String clean = hex.replaceFirst('#', '');
    if (clean.length == 6) buffer.write('ff');
    buffer.write(clean);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var room in rooms) {
      final roomRect = Rect.fromLTWH(
        (room.areaFrameX - minX + padding) * scale,
        (room.areaFrameY - minY + padding) * scale,
        room.areaFrameWidth * scale,
        room.areaFrameHeight * scale,
      );

      final roomBorderColor = _hexToColor(room.colorBorder);
      final roomTextColor = _hexToColor(room.colorText);
      const roomFillColor = Color(0xFF2A2A2A);

      final fillPaint = Paint()
        ..color = roomFillColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(roomRect, fillPaint);

      final borderPaint = Paint()
        ..color = roomBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(roomRect, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: room.areaName,
          style: TextStyle(
            color: roomTextColor,
            fontSize: BookingMapWidget.roomNameFontSize * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textX = roomRect.left + (roomRect.width - textPainter.width) / 2;
      final textY = roomRect.top - textPainter.height - 4 * scale;
      textPainter.paint(canvas, Offset(textX, textY));

      for (var pc in room.pcs) {
        final pcLeft = room.areaFrameX + pc.pcBoxLeft;
        final pcTop = room.areaFrameY + pc.pcBoxTop;

        final pcRect = Rect.fromLTWH(
          (pcLeft - minX + padding) * scale,
          (pcTop - minY + padding) * scale,
          BookingMapWidget.pcDisplaySize * scale,
          BookingMapWidget.pcDisplaySize * scale,
        );

        final isAvailable = isPcAvailable(pc);
        final pcColor = pc.enabled == 1
            ? (isAvailable ? const Color(0xFF4CAF50) : const Color(0xFF7B0D8F))
            : Colors.grey;

        final pcPaint = Paint()..color = pcColor.withOpacity(0.8);
        canvas.drawRect(pcRect, pcPaint);

        final pcBorderPaint = Paint()
          ..color = pcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(pcRect, pcBorderPaint);

        final pcTextPainter = TextPainter(
          text: TextSpan(
            text: pc.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: BookingMapWidget.pcNameFontSize * scale,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        pcTextPainter.layout();
        if (pcRect.width > 20 && pcRect.height > 20) {
          pcTextPainter.paint(
            canvas,
            Offset(
              pcRect.left + 4 * scale,
              pcRect.top + 4 * scale,
            ),
          );
        }

        if (pc.enabled != 1) {
          final iconPainter = TextPainter(
            text: const TextSpan(
              text: '⛔',
              style: TextStyle(fontSize: 16),
            ),
            textDirection: TextDirection.ltr,
          );
          iconPainter.layout();
          iconPainter.paint(
            canvas,
            Offset(
              pcRect.right - 20 * scale,
              pcRect.top,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.rooms != rooms ||
        oldDelegate.minX != minX ||
        oldDelegate.minY != minY ||
        oldDelegate.scale != scale;
  }
}

class _MapGestureDetector extends StatelessWidget {
  final List<Room> rooms;
  final double minX;
  final double minY;
  final double padding;
  final double scale;
  final void Function(PC pc) onPcTap;

  const _MapGestureDetector({
    required this.rooms,
    required this.minX,
    required this.minY,
    required this.padding,
    required this.scale,
    required this.onPcTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: rooms.expand((room) {
        return room.pcs.map((pc) {
          final pcLeft = room.areaFrameX + pc.pcBoxLeft;
          final pcTop = room.areaFrameY + pc.pcBoxTop;

          final left = (pcLeft - minX + padding) * scale;
          final top = (pcTop - minY + padding) * scale;
          final width = BookingMapWidget.pcDisplaySize * scale;
          final height = BookingMapWidget.pcDisplaySize * scale;

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: GestureDetector(
              onTap: () => onPcTap(pc),
              child: Container(color: Colors.transparent),
            ),
          );
        }).toList();
      }).toList(),
    );
  }
}