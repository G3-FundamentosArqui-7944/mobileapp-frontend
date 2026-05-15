import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/coaches_repository.dart';
import '../../data/repositories/training_sessions_repository.dart';
import '../common/async_view.dart';

/// Coach: sesiones agendadas + agregar disponibilidad.
class CoachAgendaView extends StatefulWidget {
  final int coachId;
  const CoachAgendaView({super.key, required this.coachId});

  @override
  State<CoachAgendaView> createState() => _CoachAgendaViewState();
}

class _CoachAgendaViewState extends State<CoachAgendaView> {
  late Future<List<TrainingSession>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<TrainingSessionsRepository>().byCoach(widget.coachId);
  }

  Future<void> _addAvailability() async {
    final result = await showDialog<AddAvailabilityRequest>(
      context: context,
      builder: (ctx) => const _AddAvailabilityDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<CoachesRepository>().addAvailability(widget.coachId, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilidad agregada')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAvailability,
        icon: const Icon(Icons.add),
        label: const Text('Disponibilidad'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<List<TrainingSession>>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateView(
                icon: Icons.calendar_month_outlined,
                title: 'Sin sesiones agendadas',
                subtitle: 'Agrega disponibilidad para que los atletas reserven contigo.',
              );
            }
            sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = sessions[i];
                final isPast = s.scheduledAt.isBefore(DateTime.now());
                final canComplete = !isPast && s.status == 'SCHEDULED';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(s.status),
                      child: const Icon(Icons.fitness_center, color: Colors.white),
                    ),
                    title: Text(
                      DateFormat("EEEE d 'de' MMMM, HH:mm", 'es_PE').format(s.scheduledAt),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Atleta #${s.athleteId} · ${s.durationMinutes} min · ${s.status}',
                    ),
                    trailing: canComplete
                        ? IconButton(
                            tooltip: 'Marcar como completada',
                            icon: const Icon(Icons.check, color: AppColors.success),
                            onPressed: () => _completeSession(s),
                          )
                        : null,
                  ),
                );
              },
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

  static const _labels = {
    'MONDAY': 'Lunes',
    'TUESDAY': 'Martes',
    'WEDNESDAY': 'Miércoles',
    'THURSDAY': 'Jueves',
    'FRIDAY': 'Viernes',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva disponibilidad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _day,
            items: _days
                .map((d) => DropdownMenuItem(value: d, child: Text(_labels[d]!)))
                .toList(),
            onChanged: (v) => setState(() => _day = v ?? 'MONDAY'),
            decoration: const InputDecoration(labelText: 'Día'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Inicio: ${_start.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _start);
              if (t != null) setState(() => _start = t);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Fin: ${_end.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _end);
              if (t != null) setState(() => _end = t);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            AddAvailabilityRequest(
              dayOfWeek: _day,
              startTime: _fmt(_start),
              endTime: _fmt(_end),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
