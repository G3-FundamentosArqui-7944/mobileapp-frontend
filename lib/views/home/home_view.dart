import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/sign_in_view.dart';
import '../coach/coach_agenda_view.dart';
import '../coach/coach_clients_view.dart';
import '../coach/coach_home_view.dart';
import '../coach/coach_messages_view.dart';
import '../matchmaking/coach_search_view.dart';
import '../nutrition/nutrition_view.dart';
import '../profile/profile_view.dart';
import '../training/athlete_home_view.dart';
import '../videos/video_analysis_view.dart';

/// Home con bottom navigation cuyo contenido depende del rol.
/// - ROLE_ATHLETE: Inicio, Coaches, Análisis IA, Nutrición, Perfil
/// - ROLE_COACH:   Inicio, Clientes, Agenda, Mensajes, Perfil
class HomeView extends StatefulWidget {
  final AuthenticatedUser user;
  const HomeView({super.key, required this.user});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCoach = widget.user.isCoach && !widget.user.isAthlete;
    final tabs = isCoach ? _coachTabs(l10n, widget.user) : _athleteTabs(l10n, widget.user);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthUnauthenticated,
      listener: (context, state) {
        final msg = (state as AuthUnauthenticated).message;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInView()),
          (_) => false,
        );
      },
      child: Scaffold(
        body: SafeArea(child: tabs[_index].builder(context)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.backgroundCard,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          destinations: tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.icon, color: AppColors.primary),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  List<_Tab> _athleteTabs(AppLocalizations l10n, AuthenticatedUser u) => [
        _Tab(l10n.home_tabHome, Icons.home_rounded, (_) => AthleteHomeView(user: u)),
        _Tab(l10n.home_tabCoaches, Icons.search_rounded, (_) => CoachSearchView(athleteId: u.id)),
        _Tab(l10n.home_tabAiAnalysis, Icons.videocam_rounded,
            (_) => VideoAnalysisView(userId: u.id)),
        _Tab(l10n.home_tabNutrition, Icons.restaurant_rounded,
            (_) => NutritionView(userId: u.id)),
        _Tab(l10n.home_tabProfile, Icons.person_rounded, (_) => ProfileView(user: u)),
      ];

  List<_Tab> _coachTabs(AppLocalizations l10n, AuthenticatedUser u) => [
        _Tab(l10n.home_tabHome, Icons.home_rounded, (_) => CoachHomeView(coach: u)),
        _Tab(l10n.home_tabClients, Icons.group_rounded, (_) => CoachClientsView(coachId: u.id)),
        _Tab(l10n.home_tabAgenda, Icons.calendar_month_rounded,
            (_) => CoachAgendaView(coachId: u.id)),
        _Tab(l10n.home_tabMessages, Icons.chat_bubble_outline, (_) => const CoachMessagesView()),
        _Tab(l10n.home_tabProfile, Icons.person_rounded, (_) => ProfileView(user: u)),
      ];
}

class _Tab {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  const _Tab(this.label, this.icon, this.builder);
}
