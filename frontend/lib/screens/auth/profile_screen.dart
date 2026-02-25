import 'package:flutter/material.dart';
import 'package:nhtl_mobile/models/logged_user.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.fromSupabase();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: user.userId.isEmpty
            ? const Center(child: Text('Aucun utilisateur connecté'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email : ${user.email}'),
                  Text('Nom d\'utilisateur : ${user.username ?? ''}'),
                  Text('Nom complet : ${user.fullName ?? ''}'),
                  Text('Téléphone : ${user.phone ?? ''}'),
                  Text('ID utilisateur : ${user.userId}'),
                ],
              ),
      ),
    );
  }
}
