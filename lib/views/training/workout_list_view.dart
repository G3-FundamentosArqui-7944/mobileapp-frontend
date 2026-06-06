import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/training_models.dart';
import '../../data/repositories/training_repository.dart';
import '../common/async_view.dart';
import 'workout_session_view.dart';

/// Lista de entrenamientos del atleta + FAB para iniciar uno nuevo.
class WorkoutListView extends StatefulWidget {
  final int userId;
  const WorkoutListView({super.key, required this.userId});

  @override
  State<WorkoutListView> createState() => _WorkoutListViewState();
}

class _WorkoutListViewState extends State<WorkoutListView> {
  late Future<List<WorkoutSession>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<TrainingRepository>().sessionsByUser(widget.userId);
  }

  Future<void> _startNew() async {
    final repo = context.read<TrainingRepository>();
    final title = await _promptTitle();
    if (title == null || title.trim().isEmpty) return;
    try {
      final session = await repo.startSession(
        StartWorkoutSessionRequest(
          userId: widget.userId,
          title: title.trim(),
          startedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutSessionView(sessionId: session.id),
        ),
      );
      if (mounted) setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<String?> _promptTitle() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo entrenamiento'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Ej. Pecho y tríceps',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis entrenamientos')),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<List<WorkoutSession>>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, sessions) {
            if (sessions.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyStateView(
                    icon: Icons.fitness_center,
                    title: 'Aún no registras entrenamientos',
                    subtitle: 'Toca el botón + para iniciar tu primera sesión.',
                  ),
                ],
              );
            }
            final sorted = [...sessions]
              ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _WorkoutCard(
                session: sorted[i],
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutSessionView(sessionId: sorted[i].id),
                    ),
                  );
                  if (mounted) setState(_load);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNew,
        icon: const Icon(Icons.add),
        label: const Text('Iniciar'),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;
  const _WorkoutCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _statusColor(session.status).withValues(alpha: 0.15),
                child: Icon(_statusIcon(session.status), color: _statusColor(session.status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(session.startedAt)} · ${session.exercises.length} ejercicios',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${session.totalVolume}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'volumen',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'ABANDONED':
        return Icons.cancel_outlined;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.success;
      case 'ABANDONED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
