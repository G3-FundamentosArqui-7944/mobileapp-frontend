import 'package:flutter/material.dart';

import '../common/async_view.dart';

/// Mensajería 1-a-1: el backend actual no expone este módulo, así que mostramos
/// un placeholder claro hasta que esté disponible.
class CoachMessagesView extends StatelessWidget {
  const CoachMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.chat_bubble_outline,
      title: 'Mensajería próximamente',
      subtitle:
          'El módulo de chat aún no está habilitado en el backend. Estará disponible muy pronto.',
    );
  }
}
