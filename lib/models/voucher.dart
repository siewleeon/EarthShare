import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final int points;
  final double discount;
  final String description;
  final int total;
  final DateTime expired_date;

  Voucher({
        required this.id,
        required this.points,
        required this.discount,
        required this.description,
        required this.total,
        required this.expired_date,
  });

  // Create a copy with some fields changed
  Voucher copyWith({
    String? id,
    int? points,
    double? discount,
    String? description,
    int? total,
    DateTime? expired_date,
}){
    return Voucher(
      id: id ?? this.id,
      points: points ?? this.points,
      discount: discount ?? this.discount,
      description: description ?? this.description,
      total: total ?? this.total,
      expired_date: expired_date ?? this.expired_date,
    );
  }

  factory Voucher.fromMap(Map<String, dynamic> map)
  {
    return Voucher(
      id: map['voucher_ID'] ?? '',
      points: (map['points'] ?? 0).toInteger(),
      discount: (map['discount'] ?? 0.0).toDounle(),
      description: map['description'] ?? '',
      total: (map['total'] ?? 0).toInteger(),
      expired_date: (map['expired_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap()
  {
    return {
          'voucher_ID':id,
          'points':points,
          'discount': discount,
          'description': description,
          'total': total,
          'expired_date': expired_date.toIso8601String(),
    };
  }
}