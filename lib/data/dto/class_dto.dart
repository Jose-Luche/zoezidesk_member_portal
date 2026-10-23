/// One class from `GET /member/classes` (and the `class` object returned by
/// book/cancel).
class ClassDto {
  const ClassDto({
    required this.id,
    required this.className,
    this.color,
    this.instructor,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.spotsLeft,
    required this.isFull,
    required this.booked,
  });

  /// Throws [FormatException] for rows without parseable times, so a
  /// malformed response is rejected before it reaches the cache.
  factory ClassDto.fromJson(Map<String, dynamic> json) {
    int n(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    final starts = DateTime.tryParse('${json['starts_at']}');
    final ends = DateTime.tryParse('${json['ends_at']}');
    if (starts == null || ends == null) {
      throw const FormatException('Class without start or end time');
    }
    return ClassDto(
      id: n(json['id']),
      className: json['class_name'] as String? ?? 'Class',
      color: json['color'] as String?,
      instructor: json['instructor'] as String?,
      description: json['description'] as String?,
      startsAt: starts,
      endsAt: ends,
      capacity: n(json['capacity']),
      spotsLeft: n(json['spots_left']),
      isFull: json['is_full'] == true,
      booked: json['my_booking'] == 'booked',
    );
  }

  final int id;
  final String className;
  final String? color;
  final String? instructor;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int spotsLeft;
  final bool isFull;
  final bool booked;
}
