class BodyEntry {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? waistCm;
  final double? hipsCm;
  final double? chestCm;

  BodyEntry({
    required this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.waistCm,
    this.hipsCm,
    this.chestCm,
  });

  static String idFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'heightCm': heightCm,
      'waistCm': waistCm,
      'hipsCm': hipsCm,
      'chestCm': chestCm,
    };
  }

  factory BodyEntry.fromMap(Map<String, dynamic> map) {
    return BodyEntry(
      id: map['id'] ?? '',
      date: map['date'] is String
          ? DateTime.parse(map['date'])
          : (map['date'] as DateTime),
      weightKg: map['weightKg']?.toDouble(),
      heightCm: map['heightCm']?.toDouble(),
      waistCm: map['waistCm']?.toDouble(),
      hipsCm: map['hipsCm']?.toDouble(),
      chestCm: map['chestCm']?.toDouble(),
    );
  }

  BodyEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? waistCm,
    double? hipsCm,
    double? chestCm,
  }) {
    return BodyEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      chestCm: chestCm ?? this.chestCm,
    );
  }
}
