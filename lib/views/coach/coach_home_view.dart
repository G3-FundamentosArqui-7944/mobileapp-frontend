import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/connection_requests_repository.dart';
import '../../data/repositories/training_sessions_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import '../common/async_view.dart';
import '../common/section_header.dart';

class CoachHomeView extends StatefulWidget {
  final AuthenticatedUser coach;
  const CoachHomeView({super.key, required this.coach});

  @override
  State<CoachHomeView> createState() => _CoachHomeViewState();
}

class _CoachHomeViewState extends State<CoachHomeView> {
  late Future<_CoachOverview> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final connections = context.read<ConnectionRequestsRepository>();
    final sessions = context.read<TrainingSessionsRepository>();
    _future = () async {
      final clients = await connections.coachClients(widget.coach.id);
      final pending = await connections.byCoach(widget.coach.id);
      final upcoming = await sessions.byCoach(widget.coach.id);
      return _CoachOverview(
        clients: clients,
        pending: pending.where((r) => r.status == 'PENDING').toList(),
        sessions: upcoming
            .where((s) => s.scheduledAt.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
      );
    }();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = context.watch<LocaleController>().intlLocaleCode;
    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: AsyncView<_CoachOverview>(
        future: _future,
        onRetry: () => setState(_load),
        builder: (context, data) {
          final next = data.sessions.isEmpty ? null : data.sessions.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.coachHome_greeting(widget.coach.firstName ?? l10n.coachHome_defaultName),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.coachHome_subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.group,
                      label: l10n.coachHome_activeClients,
                      value: data.clients.length.toString(),
                      color: AppColors.coachAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      label: l10n.coachHome_requests,
                      value: data.pending.length.toString(),
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.calendar_today,
                label: l10n.coachHome_upcomingSessions,
                value: data.sessions.length.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.coachHome_nextSessionSection),
              if (next == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.coachHome_noSessionsScheduled,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.fitness_center, color: Colors.white),
                    ),
                    title: Text(
                      DateFormat("EEEE d 'de' MMMM, HH:mm", intlLocale).format(next.scheduledAt),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      l10n.coachHome_athleteSessionInfo(next.athleteId, next.durationMinutes) +
                          (next.location != null ? ' · ${next.location}' : ''),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoachOverview {
  final List<ConnectionRequest> clients;
  final List<ConnectionRequest> pending;
  final List<TrainingSession> sessions;
  const _CoachOverview({
    required this.clients,
    required this.pending,
    required this.sessions,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
