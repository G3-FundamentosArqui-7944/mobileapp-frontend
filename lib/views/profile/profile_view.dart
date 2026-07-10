import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import '../membership/membership_view.dart';

class ProfileView extends StatelessWidget {
  final AuthenticatedUser user;
  const ProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCoach = user.isCoach;
    final accent = isCoach ? AppColors.coachAccent : AppColors.athleteAccent;
    final locale = context.watch<LocaleController>();

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
                  isCoach ? l10n.profile_roleCoach : l10n.profile_roleAthlete,
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
          title: l10n.profile_membershipTitle,
          subtitle: l10n.profile_membershipSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MembershipView(userId: user.id)),
          ),
        ),
        _ProfileTile(
          icon: Icons.language,
          title: l10n.profile_languageTitle,
          subtitle: locale.locale.languageCode == 'es' ? 'Español' : 'English',
          onTap: () => _showLanguagePicker(context, locale),
        ),
        _ProfileTile(
          icon: Icons.info_outline,
          title: l10n.profile_aboutTitle,
          subtitle: l10n.profile_aboutSubtitle,
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'BodyMatch',
              applicationVersion: '1.0.0',
              applicationLegalese: l10n.profile_aboutLegalese(DateTime.now().year),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.profile_logoutButton),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: () => _confirmLogout(context, l10n),
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

  Future<void> _showLanguagePicker(BuildContext context, LocaleController locale) async {
    final chosen = await showModalBottomSheet<Locale>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: locale.locale.languageCode == 'en' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, const Locale('en')),
            ),
            ListTile(
              title: const Text('Español'),
              trailing: locale.locale.languageCode == 'es' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, const Locale('es')),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) await locale.setLocale(chosen);
  }

  Future<void> _confirmLogout(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profile_logoutConfirmTitle),
        content: Text(l10n.profile_logoutConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profile_logoutConfirmButton),
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
