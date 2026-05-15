import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/connection_requests_repository.dart';
import '../../data/repositories/training_sessions_repository.dart';
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
    final messageCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar coaching'),
        content: TextField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '¿Por qué quieres entrenar con este coach?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
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
        const SnackBar(content: Text('Solicitud enviada al coach')),
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
            'Sesión agendada para ${DateFormat('dd MMM, HH:mm', 'es_PE').format(scheduledAt)}',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409
          ? 'Ese horario ya no está disponible.'
          : e.message;
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
    return Scaffold(
      appBar: AppBar(title: Text('Coach #${c.userId}')),
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
              '${c.yearsOfExperience} años de experiencia',
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
          const Text('Especialidades',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.specialties
                .map((s) => Chip(
                      label: Text(specialtyLabel(s)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Disponibilidad',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (c.availabilitySlots.isEmpty)
            const Text('El coach aún no publicó horarios.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            ...c.availabilitySlots.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: AppColors.coachAccent),
                title: Text('${s.dayOfWeek} · ${s.startTime} – ${s.endTime}'),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy ? null : _requestConnection,
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Solicitar coaching'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _scheduleSession,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Agendar sesión'),
          ),
        ],
      ),
    );
  }
}
