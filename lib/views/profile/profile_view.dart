import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../membership/membership_view.dart';

class ProfileView extends StatelessWidget {
  final AuthenticatedUser user;
  const ProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isCoach = user.isCoach;
    final accent = isCoach ? AppColors.coachAccent : AppColors.athleteAccent;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: accent.withValues(alpha: 0.18),
                child: Text(
                  _initials(user),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCoach ? 'Coach' : 'Atleta',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _ProfileTile(
          icon: Icons.workspace_premium_rounded,
          title: 'Membresía',
          subtitle: 'Planes, suscripción actual e historial',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MembershipView(userId: user.id)),
          ),
        ),
        _ProfileTile(
          icon: Icons.info_outline,
          title: 'Acerca de BodyMatch',
          subtitle: 'Versión, términos y condiciones',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'BodyMatch',
              applicationVersion: '1.0.0',
              applicationLegalese: '© ${DateTime.now().year} BodyMatch AI',
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  String _initials(AuthenticatedUser u) {
    final first = (u.firstName ?? '').trim();
    final last = (u.lastName ?? '').trim();
    String letters = '';
    if (first.isNotEmpty) letters += first[0];
    if (last.isNotEmpty) letters += last[0];
    if (letters.isEmpty) letters = u.email[0].toUpperCase();
    return letters.toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
