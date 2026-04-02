// lib/models/departure_model.dart

class DepartureModel {
  final int? id;
  final String route;
  final String pointDepart;
  final String pointArrivee;
  final String flagEmoji;
  final DateTime departureDateTime;
  final String status; // DRAFT | PUBLISHED | ARCHIVED
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DepartureModel({
    this.id,
    required this.route,
    required this.pointDepart,
    required this.pointArrivee,
    required this.flagEmoji,
    required this.departureDateTime,
    this.status = 'DRAFT',
    this.createdAt,
    this.updatedAt,
  });

  bool get isPublished => status == 'PUBLISHED';
  bool get isDraft => status == 'DRAFT';
  bool get isArchived => status == 'ARCHIVED';
  bool get isUpcoming => departureDateTime.isAfter(DateTime.now());
  bool get isPast => !isUpcoming;

  String get dateLabel {
    final d = departureDateTime;
    const months = [
      '',
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String get timeLabel {
    final h = departureDateTime.hour.toString().padLeft(2, '0');
    final m = departureDateTime.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }

  DepartureModel copyWith({
    int? id,
    String? route,
    String? pointDepart,
    String? pointArrivee,
    String? flagEmoji,
    DateTime? departureDateTime,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DepartureModel(
      id: id ?? this.id,
      route: route ?? this.route,
      pointDepart: pointDepart ?? this.pointDepart,
      pointArrivee: pointArrivee ?? this.pointArrivee,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DepartureModel.fromJson(Map<String, dynamic> json) {
    return DepartureModel(
      id: (json['id'] as num?)?.toInt(),
      route: json['route'] as String? ?? '',
      pointDepart: json['pointDepart'] as String? ?? '',
      pointArrivee: json['pointArrivee'] as String? ?? '',
      flagEmoji: json['flagEmoji'] as String? ?? '🌍',
      departureDateTime: DateTime.parse(json['departureDateTime'] as String),
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'route': route,
      'pointDepart': pointDepart,
      'pointArrivee': pointArrivee,
      'flagEmoji': flagEmoji,
      'departureDateTime': departureDateTime.toIso8601String(),
      'status': status,
    };
  }
}
