import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/coaches_repository.dart';
import '../../data/repositories/profiles_repository.dart';
import '../../data/repositories/training_sessions_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import '../common/async_view.dart';

String dayOfWeekLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'MONDAY':
      return l10n.day_monday;
    case 'TUESDAY':
      return l10n.day_tuesday;
    case 'WEDNESDAY':
      return l10n.day_wednesday;
    case 'THURSDAY':
      return l10n.day_thursday;
    case 'FRIDAY':
      return l10n.day_friday;
    case 'SATURDAY':
      return l10n.day_saturday;
    case 'SUNDAY':
      return l10n.day_sunday;
    default:
      return code;
  }
}

/// Coach: sesiones agendadas + agregar disponibilidad.
class CoachAgendaView extends StatefulWidget {
  final int coachId;
  const CoachAgendaView({super.key, required this.coachId});

  @override
  State<CoachAgendaView> createState() => _CoachAgendaViewState();
}

class _CoachAgendaViewState extends State<CoachAgendaView> {
  late Future<List<TrainingSession>> _future;
  CoachProfile? _coachProfile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<TrainingSessionsRepository>().byCoach(widget.coachId);
    context.read<ProfilesRepository>().getCoachByUserId(widget.coachId).then((profile) {
      if (mounted) setState(() => _coachProfile = profile);
    });
  }

  Future<void> _addAvailability() async {
    final result = await showDialog<AddAvailabilityRequest>(
      context: context,
      builder: (ctx) => const _AddAvailabilityDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final updated =
          await context.read<CoachesRepository>().addAvailability(widget.coachId, result);
      if (!mounted) return;
      setState(() => _coachProfile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.coachAgenda_availabilityAdded)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _completeSession(TrainingSession s) async {
    try {
      await context.read<TrainingSessionsRepository>().complete(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.coachAgenda_sessionClosed)),
      );
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = context.watch<LocaleController>().intlLocaleCode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAvailability,
        icon: const Icon(Icons.add),
        label: Text(l10n.coachAgenda_fabLabel),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<List<TrainingSession>>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, sessions) {
            sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            final slots = _coachProfile?.availabilitySlots ?? const <AvailabilitySlot>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Text(
                  l10n.coachAgenda_weeklyAvailabilityTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.coachAgenda_noAvailabilityYet,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...slots.map((slot) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event_available, color: AppColors.primary),
                          title: Text(dayOfWeekLabel(l10n, slot.dayOfWeek)),
                          subtitle: Text(
                            '${slot.startTime.substring(0, 5)} - ${slot.endTime.substring(0, 5)}',
                          ),
                        ),
                      )),
                const SizedBox(height: 20),
                Text(
                  l10n.coachAgenda_scheduledSessionsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.coachAgenda_addAvailabilityPrompt,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...sessions.map((s) {
                    final isPast = s.scheduledAt.isBefore(DateTime.now());
                    final canComplete = !isPast && s.status == 'SCHEDULED';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(s.status),
                          child: const Icon(Icons.fitness_center, color: Colors.white),
                        ),
                        title: Text(
                          DateFormat("EEEE d 'de' MMMM, HH:mm", intlLocale).format(s.scheduledAt),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          l10n.coachAgenda_athleteSessionInfo(
                              s.athleteId, s.durationMinutes, s.status),
                        ),
                        trailing: canComplete
                            ? IconButton(
                                tooltip: l10n.coachAgenda_markCompletedTooltip,
                                icon: const Icon(Icons.check, color: AppColors.success),
                                onPressed: () => _completeSession(s),
                              )
                            : null,
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

class _AddAvailabilityDialog extends StatefulWidget {
  const _AddAvailabilityDialog();

  @override
  State<_AddAvailabilityDialog> createState() => _AddAvailabilityDialogState();
}

class _AddAvailabilityDialogState extends State<_AddAvailabilityDialog> {
  String _day = 'MONDAY';
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 0);

  static const _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.coachAgenda_newAvailabilityTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _day,
            items: _days
                .map((d) => DropdownMenuItem(value: d, child: Text(dayOfWeekLabel(l10n, d))))
                .toList(),
            onChanged: (v) => setState(() => _day = v ?? 'MONDAY'),
            decoration: InputDecoration(labelText: l10n.coachAgenda_dayLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.coachAgenda_startLabel(_start.format(context))),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _start);
              if (t != null) setState(() => _start = t);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.coachAgenda_endLabel(_end.format(context))),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _end);
              if (t != null) setState(() => _end = t);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            AddAvailabilityRequest(
              dayOfWeek: _day,
              startTime: _fmt(_start),
              endTime: _fmt(_end),
            ),
          ),
          child: Text(l10n.coachAgenda_saveButton),
        ),
      ],
    );
  }
}
