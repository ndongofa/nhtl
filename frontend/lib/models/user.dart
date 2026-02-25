class User {
  final int? id; // Spring: int | Supabase: null ou inexistant
  final String? name;
  final String? email;
  final String role; // Toujours présent !

  User({
    this.id,
    this.name,
    this.email,
    required this.role,
  });

  /// Factory compatible REST backend (Spring) ou Supabase Auth
  factory User.fromJson(Map<String, dynamic> json) {
    String resolvedRole = 'user';
    // 1. Spring/backend: role au niveau racine
    if (json['role'] != null) {
      resolvedRole = json['role'];
    }
    // 2. Supabase: dans les metadata
    else if (json['user_metadata'] != null &&
        json['user_metadata']['role'] != null) {
      resolvedRole = json['user_metadata']['role'];
    }
    return User(
      id: json['id'], // Inexistant côté Supabase, présent côté Spring
      name:
          json['name'] ?? json['user_metadata']?['full_name'] ?? json['email'],
      email: json['email'],
      role: resolvedRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "role": role,
    };
  }
}
