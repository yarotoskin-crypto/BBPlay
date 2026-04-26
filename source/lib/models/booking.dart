// lib/models/booking.dart

// Вспомогательная функция для безопасного преобразования в int
int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Вспомогательная функция для парсинга duration (может быть int или String)
String _parseDuration(dynamic value) {
  if (value == null) return '0';
  if (value is int) return value.toString();
  if (value is String) return value;
  return '0';
}

// Тариф (почасовой)
class Price {
  final int id;
  final String name;
  final String pricePerHour;
  final String totalPrice;
  final int? duration;
  final String groupName;

  Price({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.totalPrice,
    this.duration,
    required this.groupName,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: _toInt(json['price_id']),
      name: json['price_name'] ?? '',
      pricePerHour: json['price_price1'] ?? '0.00',
      totalPrice: json['total_price'] ?? '0.00',
      duration: json['duration'] != null ? _toInt(json['duration']) : null,
      groupName: json['group_name'] ?? '',
    );
  }
}

// Пакет (продукт)
class Product {
  final int id;
  final String name;
  final String price;
  final String totalPrice;
  final String duration;
  final String durationMin;
  final bool isCalcDuration;
  final String showTimeStart;
  final String showTimeEnd;
  final String groupName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.totalPrice,
    required this.duration,
    required this.durationMin,
    required this.isCalcDuration,
    required this.showTimeStart,
    required this.showTimeEnd,
    required this.groupName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _toInt(json['product_id']),
      name: json['product_name'] ?? '',
      price: json['product_price'] ?? '0.00',
      totalPrice: json['total_price'] ?? '0.00',
      duration: _parseDuration(json['duration']),
      durationMin: _parseDuration(json['duration_min']),
      isCalcDuration: json['is_calc_duration'] ?? false,
      showTimeStart: json['product_show_time_start'] ?? '00:00',
      showTimeEnd: json['product_show_time_end'] ?? '23:59',
      groupName: json['group_name'] ?? '',
    );
  }
}

// Ответ от /all-prices-icafe
class PricesResponse {
  final List<Price> prices;
  final List<Product> products;

  PricesResponse({required this.prices, required this.products});

  factory PricesResponse.fromJson(Map<String, dynamic> json) {
    final pricesList = (json['prices'] as List<dynamic>? ?? [])
        .map((p) => Price.fromJson(p))
        .toList();
    final productsList = (json['products'] as List<dynamic>? ?? [])
        .map((p) => Product.fromJson(p))
        .toList();
    return PricesResponse(prices: pricesList, products: productsList);
  }
}

// ПК
// lib/models/booking.dart (фрагмент)

class PC {
  final String name;
  final String areaName;
  final bool isUsing;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String groupName;
  final String priceName;
  final int enabled; // 1 — работает, 0 — выключен
  // Новые поля для карты
  final double pcBoxLeft;
  final double pcBoxTop;
  final String pcBoxPosition;
  final String pcComment;
  final int pcConsoleType;
  final int pcIcafeId;

  PC({
    required this.name,
    required this.areaName,
    required this.isUsing,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    required this.groupName,
    required this.priceName,
    required this.enabled,
    required this.pcBoxLeft,
    required this.pcBoxTop,
    required this.pcBoxPosition,
    required this.pcComment,
    required this.pcConsoleType,
    required this.pcIcafeId,
  });

  factory PC.fromJson(Map<String, dynamic> json) {
    return PC(
      name: json['pc_name'] ?? '',
      areaName: json['pc_area_name'] ?? '',
      isUsing: json['is_using'] ?? false,
      startDate: json['start_date'],
      startTime: json['start_time'],
      endDate: json['end_date'],
      endTime: json['end_time'],
      groupName: json['pc_group_name'] ?? '',
      priceName: json['price_name'] ?? '',
      enabled: _toInt(json['pc_enabled'], defaultValue: 1),
      pcBoxLeft: (json['pc_box_left'] as num?)?.toDouble() ?? 0.0,
      pcBoxTop: (json['pc_box_top'] as num?)?.toDouble() ?? 0.0,
      pcBoxPosition: json['pc_box_position'] ?? '',
      pcComment: json['pc_comment'] ?? '',
      pcConsoleType: _toInt(json['pc_console_type']),
      pcIcafeId: _toInt(json['pc_icafe_id']),
    );
  }
}

// Ответ от /available-pcs-for-booking
class AvailablePCsResponse {
  final String timeFrame;
  final List<PC> pcList;

  AvailablePCsResponse({required this.timeFrame, required this.pcList});

  factory AvailablePCsResponse.fromJson(Map<String, dynamic> json) {
    final pcList = (json['pc_list'] as List<dynamic>? ?? [])
        .map((p) => PC.fromJson(p))
        .toList();
    return AvailablePCsResponse(
      timeFrame: json['time_frame']?.toString() ?? '30',
      pcList: pcList,
    );
  }
}

// Ответ от /struct-rooms-icafe
class StructRoomsResponse {
  final List<Room> rooms;
  StructRoomsResponse({required this.rooms});

  factory StructRoomsResponse.fromJson(Map<String, dynamic> json) {
    final roomsList = (json['rooms'] as List<dynamic>? ?? [])
        .map((r) => Room.fromJson(r))
        .toList();
    return StructRoomsResponse(rooms: roomsList);
  }
}

// lib/models/booking.dart (фрагмент)

class Room {
  final int areaIcafeId;
  final String areaName;
  final String? colorBorder;
  final String? colorText;
  final List<PC> pcs;
  // Новые поля для карты
  final int areaIndex;
  final double areaFrameX;
  final double areaFrameY;
  final double areaFrameWidth;
  final double areaFrameHeight;
  final int areaAllowBooking;
  final int allowPayByRoom;

  Room({
    required this.areaIcafeId,
    required this.areaName,
    this.colorBorder,
    this.colorText,
    required this.pcs,
    required this.areaIndex,
    required this.areaFrameX,
    required this.areaFrameY,
    required this.areaFrameWidth,
    required this.areaFrameHeight,
    required this.areaAllowBooking,
    required this.allowPayByRoom,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final pcsList = (json['pcs_list'] as List<dynamic>? ?? [])
        .map((p) => PC.fromJson(p))
        .toList();
    return Room(
      areaIcafeId: _toInt(json['area_icafe_id']),
      areaName: json['area_name'] ?? '',
      colorBorder: json['color_border'],
      colorText: json['color_text'],
      pcs: pcsList,
      areaIndex: _toInt(json['area_index']),
      areaFrameX: (json['area_frame_x'] as num?)?.toDouble() ?? 0.0,
      areaFrameY: (json['area_frame_y'] as num?)?.toDouble() ?? 0.0,
      areaFrameWidth: (json['area_frame_width'] as num?)?.toDouble() ?? 0.0,
      areaFrameHeight: (json['area_frame_height'] as num?)?.toDouble() ?? 0.0,
      areaAllowBooking: _toInt(json['area_allow_booking']),
      allowPayByRoom: _toInt(json['allow_pay_by_room']),
    );
  }
}

class UserBooking {
  final int productId;
  final String pcName;
  final String from;
  final String to;
  final int mins;
  final String description;
  final String memberOfferId;
  final String memberAccount;
  final int? cafeId; // <-- теперь nullable

  UserBooking({
    required this.productId,
    required this.pcName,
    required this.from,
    required this.to,
    required this.mins,
    required this.description,
    required this.memberOfferId,
    required this.memberAccount,
    this.cafeId,
  });

  factory UserBooking.fromJson(Map<String, dynamic> json, {int? cafeId}) {
    return UserBooking(
      productId: json['product_id'],
      pcName: json['product_pc_name'] ?? '',
      from: json['product_available_date_local_from'] ?? '',
      to: json['product_available_date_local_to'] ?? '',
      mins: json['product_mins'],
      description: json['product_description'] ?? '',
      memberOfferId: json['member_offer_id'].toString(),
      memberAccount: json['member_account'] ?? '',
      cafeId: cafeId,
    );
  }
}