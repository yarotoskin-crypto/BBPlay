// lib/widgets/booking_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test1/models/booking.dart';
import 'package:test1/models/cafe.dart';
import 'package:test1/services/api_service.dart';
import 'package:test1/services/auth_service.dart';
import 'package:test1/services/booking_form_service.dart';
import 'package:test1/widgets/booking_map_widget.dart';
import 'package:test1/widgets/pc_list_widget.dart';

class BookingTab extends StatefulWidget {
  final int? initialCafeId;
  final String? initialDate;
  final String? initialTime;
  final int? initialDuration;

  const BookingTab({
    super.key,
    this.initialCafeId,
    this.initialDate,
    this.initialTime,
    this.initialDuration,
  });

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final BookingFormService _formService = BookingFormService();

  List<Cafe> _cafes = [];
  Cafe? _selectedCafe;
  StructRoomsResponse? _structRooms;
  AvailablePCsResponse? _availabilityResponse;
  PricesResponse? _pricesResponse;
  bool _isLoadingCafes = true;
  bool _isLoadingStruct = false;
  bool _isCheckingAvailability = false;
  bool _isProcessing = false;
  String? _error;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMins = 60;

  final List<int> _durationOptions = [30, 60, 120, 180, 240, 300];
  late ViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = _formService.viewMode; // восстанавливаем режим
    _loadInitialParams();
    _loadCafes();
  }

  void _loadInitialParams() {
    if (widget.initialCafeId != null) {
      _selectedCafe = null;
      if (widget.initialDate != null) {
        _selectedDate = DateTime.tryParse(widget.initialDate!);
      }
      if (widget.initialTime != null) {
        final parts = widget.initialTime!.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
      if (widget.initialDuration != null) {
        _durationMins = widget.initialDuration!;
      }
      _saveToService();
    } else {
      final savedCafeId = _formService.cafeId;
      if (savedCafeId != null) {
        _selectedCafe = null;
      }
      if (_formService.date != null) {
        _selectedDate = DateTime.tryParse(_formService.date!);
      }
      if (_formService.time != null) {
        final parts = _formService.time!.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
      _durationMins = _formService.duration ?? 60;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _saveToService() {
    _formService.save(
      cafeId: _selectedCafe?.icafeId,
      date: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
      time: _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : null,
      duration: _durationMins,
      viewMode: _viewMode,
    );
  }

  Future<void> _loadCafes() async {
    try {
      final cafes = await _apiService.getCafes();
      if (!mounted) return;
      setState(() {
        _cafes = cafes;
        if (widget.initialCafeId != null) {
          _selectedCafe = cafes.firstWhere(
            (c) => c.icafeId == widget.initialCafeId,
            orElse: () => cafes.first,
          );
        } else if (_formService.cafeId != null) {
          _selectedCafe = cafes.firstWhere(
            (c) => c.icafeId == _formService.cafeId,
            orElse: () => cafes.first,
          );
        } else if (cafes.isNotEmpty) {
          _selectedCafe = cafes.first;
        }
        _isLoadingCafes = false;
      });
      if (_selectedCafe != null) {
        _loadStructRooms();
        _loadPrices();
        _saveToService();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingCafes = false;
      });
    }
  }

  Future<void> _loadStructRooms() async {
    if (_selectedCafe == null) return;
    setState(() {
      _isLoadingStruct = true;
      _error = null;
    });
    try {
      final struct = await _apiService.getStructRooms(_selectedCafe!.icafeId);
      if (!mounted) return;
      setState(() {
        _structRooms = struct;
        _isLoadingStruct = false;
      });
      if (_selectedDate != null && _selectedTime != null) {
        _checkAvailability();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingStruct = false;
      });
    }
  }

  Future<void> _loadPrices() async {
    if (_selectedCafe == null) return;
    try {
      String? bookingDate;
      if (_selectedDate != null) {
        bookingDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }
      final user = _authService.currentUser;
      final memberId = user != null ? int.tryParse(user.memberId) : null;
      final prices = await _apiService.getPrices(
        cafeId: _selectedCafe!.icafeId,
        bookingDate: bookingDate,
        mins: _durationMins,
        memberId: memberId,
      );
      if (!mounted) return;
      setState(() {
        _pricesResponse = prices;
      });
    } catch (e) {
      print('Ошибка загрузки цен: $e');
    }
  }

  Future<void> _checkAvailability() async {
    if (_selectedCafe == null || _selectedDate == null || _selectedTime == null) return;

    setState(() {
      _isCheckingAvailability = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final response = await _apiService.getAvailablePCs(
        cafeId: _selectedCafe!.icafeId,
        dateStart: dateStr,
        timeStart: timeStr,
        mins: _durationMins,
        isFindWindow: true,
      );

      if (!mounted) return;
      setState(() {
        _availabilityResponse = response;
        _isCheckingAvailability = false;
      });
      _loadPrices();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _createBooking(PC pc) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showSnackBar('Не авторизован', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      await _apiService.createBooking(
        icafeId: _selectedCafe!.icafeId,
        pcName: pc.name,
        memberAccount: user.username,
        memberId: int.parse(user.memberId),
        startDate: dateStr,
        startTime: timeStr,
        mins: _durationMins,
        privateKey: user.privateKey,
      );

      if (!mounted) return;
      _showSnackBar('Бронирование успешно создано!');
      _loadStructRooms();
      setState(() {
        _availabilityResponse = null;
      });
      if (_selectedDate != null && _selectedTime != null) {
        _checkAvailability();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_formatError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _bookPackage(Product product) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showSnackBar('Не авторизован', isError: true);
      return;
    }

    if (product.isCalcDuration) {
      final minDur = int.tryParse(product.durationMin) ?? 0;
      if (_durationMins < minDur) {
        _showSnackBar('Минимальная длительность пакета: $minDur мин.', isError: true);
        return;
      }
    } else {
      final packDur = int.tryParse(product.duration) ?? 0;
      if (_durationMins != packDur) {
        _showSnackBar('Для этого пакета длительность должна быть $packDur мин.', isError: true);
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      await _apiService.createBooking(
        icafeId: _selectedCafe!.icafeId,
        pcName: '',
        memberAccount: user.username,
        memberId: int.parse(user.memberId),
        startDate: dateStr,
        startTime: timeStr,
        mins: _durationMins,
        privateKey: user.privateKey,
        productId: product.id,
      );

      if (!mounted) return;
      _showSnackBar('Пакет "${product.name}" успешно забронирован!');
      _loadStructRooms();
      setState(() {
        _availabilityResponse = null;
      });
      if (_selectedDate != null && _selectedTime != null) {
        _checkAvailability();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_formatError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _formatError(String error) {
    String msg = error;
    if (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
    if (msg.contains('Insufficient')) return 'Недостаточно средств на балансе';
    if (msg.contains('You')) return 'У вас уже есть бронирование на это время';
    if (msg.contains('occupied')) return 'Этот компьютер уже занят';
    if (msg.contains('Не удалось забронировать')) return 'Не удалось забронировать. Попробуйте другое время или компьютер.';
    return 'Ошибка: $msg';
  }

void _showSnackBar(String message, {bool isError = false}) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: isError ? Colors.red : const Color(0xFF7B0D8F),
    ),
  );
}

  bool _isPcAvailable(PC pc) {
    if (_availabilityResponse == null) return true;
    try {
      final found = _availabilityResponse!.pcList.firstWhere((p) => p.name == pc.name);
      return !found.isUsing;
    } catch (_) {
      return false;
    }
  }

  PC? _findPcInAvailability(String pcName) {
    if (_availabilityResponse == null) return null;
    try {
      return _availabilityResponse!.pcList.firstWhere((p) => p.name == pcName);
    } catch (_) {
      return null;
    }
  }

  bool _isPackageAvailable(Product product) {
    if (_selectedTime == null) return true;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate?.year ?? now.year,
      _selectedDate?.month ?? now.month,
      _selectedDate?.day ?? now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
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

  String _getPriceForPC(PC pc) {
    if (_pricesResponse == null) return 'Цена не определена';

    Price? exactPrice;
    try {
      exactPrice = _pricesResponse!.prices.firstWhere(
        (p) => p.groupName == pc.groupName && p.duration == _durationMins,
      );
    } catch (_) {}

    if (exactPrice != null) {
      return '${exactPrice.totalPrice} ₽';
    }

    Price? basePrice;
    try {
      basePrice = _pricesResponse!.prices.firstWhere((p) => p.groupName == pc.groupName);
    } catch (_) {
      basePrice = _pricesResponse!.prices.isNotEmpty ? _pricesResponse!.prices.first : null;
    }

    if (basePrice != null) {
      final pricePerHour = double.tryParse(basePrice.pricePerHour) ?? 0.0;
      final hours = _durationMins / 60.0;
      final calculated = (pricePerHour * hours).toStringAsFixed(2);
      return '$calculated ₽';
    }

    Product? exactProduct;
    try {
      exactProduct = _pricesResponse!.products.firstWhere(
        (p) => p.groupName == pc.groupName && p.duration == _durationMins.toString(),
      );
    } catch (_) {}

    if (exactProduct != null) {
      return '${exactProduct.totalPrice} ₽ (пакет)';
    }

    return 'Цена не указана';
  }

  void _showPcDetails(PC pc) {
    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar('Сначала выберите дату и время');
      return;
    }

    final isAvailable = _isPcAvailable(pc);
    final availabilityData = _findPcInAvailability(pc.name);
    String availabilityText;
    String? freeTimeText;

    if (isAvailable) {
      availabilityText = '✅ Доступен';
    } else {
      availabilityText = '❌ Недоступен';
      if (availabilityData != null && availabilityData.endTime != null && availabilityData.endTime!.isNotEmpty) {
        freeTimeText = 'Освободится: ${_formatTime(availabilityData.endTime!)}';
      } else {
        freeTimeText = 'Освободится: Неизвестно';
      }
    }

    final priceText = _getPriceForPC(pc);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/komp.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: const Color(0xFF1D1D1D),
                    child: const Center(
                      child: Icon(Icons.computer, size: 64, color: Color(0xFF7B0D8F)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(pc.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(pc.areaName, style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16)),
              const SizedBox(height: 16),
              _buildDetailRow('Статус', availabilityText),
              if (freeTimeText != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Освободится', freeTimeText.replaceFirst('Освободится: ', '')),
              ],
              const SizedBox(height: 12),
              _buildDetailRow('Стоимость', priceText),
              const SizedBox(height: 8),
              _buildDetailRow('Длительность', '$_durationMins мин.'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7B0D8F)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Отмена', style: TextStyle(color: Color(0xFF7B0D8F))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (pc.enabled != 1 || !isAvailable)
                          ? null
                          : () {
                              Navigator.pop(context);
                              _createBooking(pc);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('Забронировать', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

void _showPackageDetails(Product product) {
  if (_selectedDate == null || _selectedTime == null) {
    _showSnackBar('Сначала выберите дату и время');
    return;
  }

  final isReal = product.id != -1;
  final isAvailable = isReal && _isPackageAvailable(product);
  final availabilityText = isAvailable ? '✅ Доступен' : '❌ Недоступен';
  final priceText = isReal ? '${product.totalPrice} ₽' : 'Неизвестно';
  final durationText = isReal
      ? (product.isCalcDuration
          ? 'от ${product.durationMin} мин.'
          : '${product.duration} мин.')
      : 'Неизвестно';

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2A2A2A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/komp.png',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: const Color(0xFF1D1D1D),
                  child: const Center(
                    child: Icon(Icons.card_giftcard, size: 64, color: Color(0xFF7B0D8F)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Статус', availabilityText),
            const SizedBox(height: 12),
            _buildDetailRow('Стоимость', priceText),
            const SizedBox(height: 8),
            _buildDetailRow('Длительность', durationText),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7B0D8F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отмена', style: TextStyle(color: Color(0xFF7B0D8F))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !isAvailable
                        ? null
                        : () {
                            Navigator.pop(context);
                            _bookPackage(product);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Забронировать', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return timeStr;
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCafes();
        if (_selectedCafe != null) {
          await _loadStructRooms();
          await _loadPrices();
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2A2A2A),
                child: Column(
                  children: [
                    DropdownButtonFormField<Cafe>(
                      initialValue: _selectedCafe,
                      dropdownColor: const Color(0xFF1D1D1D),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1D1D1D),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _cafes.map((cafe) {
                        return DropdownMenuItem(
                          value: cafe,
                          child: Text(cafe.address, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (cafe) {
                        setState(() {
                          _selectedCafe = cafe;
                          _structRooms = null;
                          _availabilityResponse = null;
                        });
                        _saveToService();
                        if (cafe != null) {
                          _loadStructRooms();
                          _loadPrices();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(primary: Color(0xFF7B0D8F)),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                                _saveToService();
                                if (_selectedTime != null) _checkAvailability();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1D1D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedDate == null ? 'Дата' : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
Expanded(
  child: InkWell(
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() => _selectedTime = time);
        _saveToService();
        if (_selectedDate != null) _checkAvailability();
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _selectedTime == null ? 'Время' : _formatTimeOfDay(_selectedTime!),
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
),

                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _durationMins,
                            dropdownColor: const Color(0xFF1D1D1D),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1D1D1D),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            items: _durationOptions.map((mins) {
                              String label = mins == 30 ? '0.5 ч.' : '${mins ~/ 60} ч.';
                              return DropdownMenuItem(value: mins, child: Text(label));
                            }).toList(),
                            onChanged: (mins) {
                              setState(() => _durationMins = mins!);
                              _saveToService();
                              _loadPrices();
                              if (_selectedDate != null && _selectedTime != null) _checkAvailability();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Переключатель режима (без подписи)
                    SegmentedButton<ViewMode>(
                      segments: const [
                        ButtonSegment<ViewMode>(
                          value: ViewMode.list,
                          label: Text('Список'),
                          icon: Icon(Icons.list),
                        ),
                        ButtonSegment<ViewMode>(
                          value: ViewMode.map,
                          label: Text('Карта'),
                          icon: Icon(Icons.map),
                        ),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (Set<ViewMode> newSelection) {
                        setState(() {
                          _viewMode = newSelection.first;
                          _saveToService(); // сохраняем выбранный режим
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF4CAF50);
                          }
                          return const Color(0xFF1D1D1D);
                        }),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Доступен', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: const Color(0xFF7B0D8F), width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Недоступен', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isCheckingAvailability)
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFF2A2A2A),
                  color: Color(0xFF7B0D8F),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingCafes || _isLoadingStruct) {
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
                  _isLoadingStruct = true;
                  _error = null;
                });
                _loadStructRooms();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B0D8F)),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_structRooms == null || _structRooms!.rooms.isEmpty) {
      return const Center(child: Text('Нет данных о зале', style: TextStyle(color: Colors.white)));
    }

    if (_viewMode == ViewMode.map) {
      if (_selectedCafe == null) {
        return const Center(child: Text('Выберите клуб', style: TextStyle(color: Colors.white)));
      }
      return BookingMapWidget(
        cafeId: _selectedCafe!.icafeId,
        pricesResponse: _pricesResponse,
        isPcAvailable: _isPcAvailable,
        onPcTap: (pc) => _showPcDetails(pc),
        onPackageTap: (product) => _showPackageDetails(product),
        showMessage: _showSnackBar,
        isDateTimeSelected: _selectedDate != null && _selectedTime != null,
      );
    }

    final rooms = _structRooms!.rooms;
    final isDateTimeSelected = _selectedDate != null && _selectedTime != null;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.areaName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PcListWidget(
              room: room,
              pricesResponse: _pricesResponse,
              isPcAvailable: _isPcAvailable,
              isPackageAvailable: _isPackageAvailable,
              onPcTap: (pc) => _showPcDetails(pc),
              onPackageTap: (product) => _showPackageDetails(product),
              isDateTimeSelected: isDateTimeSelected,
              showMessage: _showSnackBar,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}