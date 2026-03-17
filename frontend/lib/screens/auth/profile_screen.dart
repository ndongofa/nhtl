import 'package:flutter/material.dart';
import 'package:sama/models/logged_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.fromSupabase();

    final identifier = (user.email != null && user.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : ((user.phone ?? '').trim().isNotEmpty ? user.phone!.trim() : '');

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: user.userId.isEmpty
            ? const Center(child: Text('Aucun utilisateur connecté'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Identifiant : $identifier'),
                  Text('Email : ${user.email ?? ''}'),
                  Text('Téléphone : ${user.phone ?? ''}'),
                  Text('Nom d\'utilisateur : ${user.username ?? ''}'),
                  Text('Nom complet : ${user.fullName ?? ''}'),
                  Text('ID utilisateur : ${user.userId}'),
                ],
              ),
      ),
    );
  }
}
