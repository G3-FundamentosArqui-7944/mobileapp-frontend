import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/connection_requests_repository.dart';
import '../../data/repositories/training_sessions_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import '../coach/coach_agenda_view.dart' show dayOfWeekLabel;
import 'coach_search_view.dart' show specialtyLabel;

/// Detalle del coach con acciones: solicitar conexión + agendar sesión.
class CoachDetailView extends StatefulWidget {
  final CoachProfile coach;
  final int athleteId;

  const CoachDetailView({super.key, required this.coach, required this.athleteId});

  @override
  State<CoachDetailView> createState() => _CoachDetailViewState();
}

class _CoachDetailViewState extends State<CoachDetailView> {
  bool _busy = false;

  Future<void> _requestConnection() async {
    final l10n = AppLocalizations.of(context)!;
    final messageCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.coachDetail_requestDialogTitle),
        content: TextField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.coachDetail_requestDialogHint,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.coachDetail_sendButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<ConnectionRequestsRepository>().request(
            CreateConnectionRequest(
              athleteId: widget.athleteId,
              coachId: widget.coach.userId,
              message: messageCtrl.text.trim().isEmpty ? null : messageCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.coachDetail_requestSentSnackbar)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scheduleSession() async {
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = context.read<LocaleController>().intlLocaleCode;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;

    final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _busy = true);
    try {
      await context.read<TrainingSessionsRepository>().schedule(
            ScheduleTrainingSessionRequest(
              athleteId: widget.athleteId,
              coachId: widget.coach.userId,
              scheduledAt: scheduledAt,
              durationMinutes: 60,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.coachDetail_sessionScheduledFor(
                DateFormat('dd MMM, HH:mm', intlLocale).format(scheduledAt)),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409 ? l10n.coachDetail_slotUnavailable : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coach;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachSearch_coachIdLabel(c.userId))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.coachAccent.withValues(alpha: 0.18),
              child: const Icon(Icons.sports, size: 40, color: AppColors.coachAccent),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.coachDetail_yearsExperience(c.yearsOfExperience),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          if ((c.biography ?? '').isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(c.biography!),
              ),
            ),
          const SizedBox(height: 12),
          Text(l10n.coachDetail_specialtiesTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.specialties
                .map((s) => Chip(
                      label: Text(specialtyLabel(l10n, s)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(l10n.coachDetail_availabilityTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (c.availabilitySlots.isEmpty)
            Text(l10n.coachDetail_noAvailabilityPublished,
                style: const TextStyle(color: AppColors.textSecondary))
          else
            ...c.availabilitySlots.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.coachAccent),
                title: Text('${dayOfWeekLabel(l10n, s.dayOfWeek)} · ${s.startTime} – ${s.endTime}'),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy ? null : _requestConnection,
            icon: const Icon(Icons.handshake_outlined),
            label: Text(l10n.coachDetail_requestCoachingButton),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scheduleSession,
            icon: const Icon(Icons.calendar_month),
            label: Text(l10n.coachDetail_scheduleSessionButton),
          ),
        ],
      ),
    );
  }
}
