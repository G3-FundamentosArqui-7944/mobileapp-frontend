import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'sign_up_view.dart';

/// Selector de rol antes del registro: Atleta o Coach.
/// El backend expone endpoints separados (/sign-up/athlete, /sign-up/coach).
class RoleSelectorView extends StatelessWidget {
  const RoleSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige cómo te unes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Quién eres en BodyMatch?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu rol define cómo será tu experiencia. Lo puedes cambiar más adelante.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'Soy atleta',
                description:
                    'Quiero entrenar, recibir feedback con IA, encontrar coaches y registrar mi nutrición.',
                icon: Icons.directions_run,
                accent: AppColors.athleteAccent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpView(asCoach: false)),
                ),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Soy coach',
                description:
                    'Quiero ofrecer mis servicios, gestionar clientes y agendar sesiones de entrenamiento.',
                icon: Icons.sports,
                accent: AppColors.coachAccent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpView(asCoach: true)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
