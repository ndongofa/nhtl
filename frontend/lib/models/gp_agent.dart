class GpAgent {
  final int id;
  final String prenom;
  final String nom;
  final String? phoneNumber;
  final String? email;
  final bool isActive;

  GpAgent({
    required this.id,
    required this.prenom,
    required this.nom,
    this.phoneNumber,
    this.email,
    required this.isActive,
  });

  String get fullName => '${prenom.trim()} ${nom.trim()}'.trim();

  factory GpAgent.fromJson(Map<String, dynamic> json) {
    return GpAgent(
      id: (json['id'] as num).toInt(),
      prenom: (json['prenom'] ?? '').toString(),
      nom: (json['nom'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      isActive: (json['isActive'] is bool)
          ? (json['isActive'] as bool)
          : (json['isActive']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': prenom,
      'nom': nom,
      'phoneNumber': phoneNumber,
      'email': email,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'prenom': prenom,
      'nom': nom,
      'phoneNumber': phoneNumber,
      'email': email,
      'isActive': isActive,
    };
  }
}
