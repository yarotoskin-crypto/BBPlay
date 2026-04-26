// lib/services/booking_form_service.dart

enum ViewMode { list, map }

class BookingFormService {
  static final BookingFormService _instance = BookingFormService._internal();
  factory BookingFormService() => _instance;
  BookingFormService._internal();

  int? cafeId;
  String? date;
  String? time;
  int? duration;
  ViewMode viewMode = ViewMode.list; // по умолчанию список

  void save({
    int? cafeId,
    String? date,
    String? time,
    int? duration,
    ViewMode? viewMode,
  }) {
    this.cafeId = cafeId;
    this.date = date;
    this.time = time;
    this.duration = duration;
    if (viewMode != null) {
      this.viewMode = viewMode;
    }
  }

  void clear() {
    cafeId = null;
    date = null;
    time = null;
    duration = null;
    viewMode = ViewMode.list;
  }
}