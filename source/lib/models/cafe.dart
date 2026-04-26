class Cafe {
  final int icafeId;
  final String address;

  Cafe({required this.icafeId, required this.address});

  factory Cafe.fromJson(Map<String, dynamic> json) {
    return Cafe(
      icafeId: json['icafe_id'] as int,
      address: json['address'] as String,
    );
  }
}