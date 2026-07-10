import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/async_view.dart';

/// Mensajería 1-a-1: el backend actual no expone este módulo, así que mostramos
/// un placeholder claro hasta que esté disponible.
class CoachMessagesView extends StatelessWidget {
  const CoachMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.chat_bubble_outline,
      title: l10n.coachMessages_title,
      subtitle: l10n.coachMessages_subtitle,
    );
  }
}
