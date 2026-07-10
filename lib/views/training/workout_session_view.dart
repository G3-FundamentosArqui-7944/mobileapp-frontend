import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/training_models.dart';
import '../../data/repositories/training_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/async_view.dart';
import '../common/section_header.dart';

/// Detalle de una sesión de entrenamiento. Permite añadir ejercicios y
/// completarla. Se carga por id porque post-add/post-complete el backend
/// devuelve la sesión completa actualizada (la guardamos en _session y la
/// usamos para reconstruir la UI sin refetchear).
class WorkoutSessionView extends StatefulWidget {
  final int sessionId;
  const WorkoutSessionView({super.key, required this.sessionId});

  @override
  State<WorkoutSessionView> createState() => _WorkoutSessionViewState();
}

class _WorkoutSessionViewState extends State<WorkoutSessionView> {
  late Future<WorkoutSession> _future;
  WorkoutSession? _session;

  @override
  void initState() {
    super.initState();
    _future = context.read<TrainingRepository>().getSession(widget.sessionId);
  }

  bool get _isCompleted => (_session?.status ?? 'IN_PROGRESS') == 'COMPLETED';

  Future<void> _addExercise() async {
    final repo = context.read<TrainingRepository>();
    final req = await showModalBottomSheet<AddExerciseExecutionRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddExerciseSheet(),
    );
    if (req == null) return;
    try {
      final updated = await repo.addExercise(widget.sessionId, req);
      if (!mounted) return;
      setState(() => _session = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _complete() async {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<TrainingRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutSession_completeDialogTitle),
        content: Text(l10n.workoutSession_completeDialogMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.workoutSession_completeButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updated = await repo.completeSession(widget.sessionId);
      if (!mounted) return;
      setState(() => _session = updated);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.workoutSession_completedSnackbar)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutSession_appBarTitle)),
      body: _session != null
          ? _body(l10n, _session!)
          : AsyncView<WorkoutSession>(
              future: _future,
              builder: (context, s) {
                _session = s;
                return _body(l10n, s);
              },
            ),
      floatingActionButton: _isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: Text(l10n.workoutSession_exerciseFabLabel),
            ),
    );
  }

  Widget _body(AppLocalizations l10n, WorkoutSession s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        _HeaderCard(session: s),
        const SizedBox(height: 16),
        SectionHeader(
          title: l10n.workoutSession_exercisesSection,
          subtitle: l10n.workoutSession_registeredCount(s.exercises.length),
          trailing: _isCompleted
              ? null
              : OutlinedButton.icon(
                  onPressed: _complete,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(l10n.workoutSession_completeButton),
                ),
        ),
        const SizedBox(height: 4),
        if (s.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyStateView(
              icon: Icons.fitness_center_outlined,
              title: l10n.workoutSession_emptyTitle,
              subtitle: l10n.workoutSession_emptySubtitle,
            ),
          )
        else
          ...s.exercises.map((e) => _ExerciseTile(execution: e)),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final WorkoutSession session;
  const _HeaderCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: session.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.workoutSession_startedAt(_fmt(session.startedAt)) +
                (session.completedAt != null
                    ? l10n.workoutSession_closedSuffix(_fmt(session.completedAt!))
                    : ''),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                label: l10n.workoutSession_exercisesSection,
                value: session.exercises.length.toString(),
              ),
              const SizedBox(width: 24),
              _Stat(label: l10n.workoutSession_volumeStat, value: session.totalVolume.toString()),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.day}/${l.month} $hh:$mm';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (status) {
      'COMPLETED' => (AppColors.success, l10n.workoutSession_statusCompleted),
      'ABANDONED' => (AppColors.error, l10n.workoutSession_statusAbandoned),
      _ => (AppColors.primary, l10n.workoutSession_statusInProgress),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseExecution execution;
  const _ExerciseTile({required this.execution});

  @override
  Widget build(BuildContext context) {
    final loadPart = execution.load == null
        ? ''
        : ' · ${execution.load}${execution.loadUnit ?? ''}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.backgroundCard,
          child: Icon(Icons.fitness_center, color: AppColors.primary),
        ),
        title: Text(
          execution.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${execution.sets} x ${execution.reps}$loadPart',
        ),
        trailing: execution.durationSeconds == null
            ? null
            : Text('${execution.durationSeconds}s'),
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  const _AddExerciseSheet();

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');
  final _loadCtrl = TextEditingController();
  String _loadUnit = 'kg';
  final _durationCtrl = TextEditingController();
  final _restCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _loadCtrl.dispose();
    _durationCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final load = _loadCtrl.text.trim();
    final duration = _durationCtrl.text.trim();
    final rest = _restCtrl.text.trim();
    Navigator.of(context).pop(
      AddExerciseExecutionRequest(
        exerciseName: _nameCtrl.text.trim(),
        sets: int.parse(_setsCtrl.text),
        reps: int.parse(_repsCtrl.text),
        load: load.isEmpty ? null : num.tryParse(load),
        loadUnit: load.isEmpty ? null : _loadUnit,
        durationSeconds: duration.isEmpty ? null : int.tryParse(duration),
        restSeconds: rest.isEmpty ? null : int.tryParse(rest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.workoutSession_addExerciseTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.workoutSession_exerciseNameLabel,
                hintText: l10n.workoutSession_exerciseNameHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.common_requiredField : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.workoutSession_setsLabel),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                        ? null
                        : l10n.workoutSession_greaterThanZero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.workoutSession_repsLabel),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                        ? null
                        : l10n.workoutSession_greaterThanZero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _loadCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.workoutSession_loadLabel),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    initialValue: _loadUnit,
                    decoration: InputDecoration(labelText: l10n.workoutSession_unitLabel),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lb', child: Text('lb')),
                    ],
                    onChanged: (v) => setState(() => _loadUnit = v ?? 'kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.workoutSession_durationLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _restCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.workoutSession_restLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(l10n.workoutSession_addButton),
            ),
          ],
        ),
      ),
    );
  }
}
