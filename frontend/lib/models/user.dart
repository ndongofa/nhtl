class User {
  final String id;
  final String? prenom;
  final String? nom;
  final String? email;
  final String? phone;
  final String role;
  final DateTime? createdAt;

  User({
    required this.id,
    this.prenom,
    this.nom,
    this.email,
    this.phone,
    required this.role,
    this.createdAt,
  });

  String get displayName {
    final p = (prenom ?? '').trim();
    final n = (nom ?? '').trim();
    final both = ('$p $n').trim();
    return both.isEmpty ? (email ?? phone ?? id) : both;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      prenom: json['prenom'] as String?,
      nom: json['nom'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: (json['role'] as String?) ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'phone': phone,
        'role': role,
        'created_at': createdAt?.toIso8601String(),
      };
}
