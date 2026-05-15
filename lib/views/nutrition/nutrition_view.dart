import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../common/async_view.dart';
import '../common/section_header.dart';
import 'nutrition_analysis_view.dart';

/// Dashboard nutricional del atleta: resumen diario, plan activo y comidas.
class NutritionView extends StatefulWidget {
  final int userId;
  const NutritionView({super.key, required this.userId});

  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  late Future<_NutritionDashboard> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<NutritionRepository>();
    _future = () async {
      final today = DateTime.now();
      final summary = await repo.dailySummary(widget.userId, date: today);
      final plan = await repo.activePlanForUser(widget.userId);
      final meals = await repo.mealsByUser(
        widget.userId,
        from: DateTime(today.year, today.month, today.day),
        to: today,
      );
      return _NutritionDashboard(summary: summary, plan: plan, meals: meals);
    }();
  }

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto del plato'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    try {
      final analysis = await context.read<NutritionRepository>().analyzeImage(
            userId: widget.userId,
            image: File(picked.path),
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NutritionAnalysisDetailView(
            analysisId: analysis.id,
            userId: widget.userId,
          ),
        ),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndAnalyze,
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Analizar comida'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<_NutritionDashboard>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                const Text(
                  'Hoy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _MacroCard(
                  consumed: data.summary,
                  target: data.plan?.dailyTargets ?? MacroSummary.empty,
                ),
                const SizedBox(height: 20),
                if (data.plan != null) ...[
                  const SectionHeader(title: 'Plan activo'),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.flag, color: AppColors.accent),
                      title: Text(data.plan!.name),
                      subtitle: Text(
                        'Hasta ${DateFormat('d MMM y', 'es_PE').format(data.plan!.endDate ?? DateTime.now().add(const Duration(days: 30)))}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SectionHeader(title: 'Comidas de hoy'),
                if (data.meals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Aún no registraste ninguna comida.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...data.meals.map(_buildMealCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMealCard(MealRecord m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.accent,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          m.description ?? _mealLabel(m.mealType),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${m.macros.calories.toStringAsFixed(0)} kcal · '
          'P ${m.macros.proteinGrams.toStringAsFixed(0)}g · '
          'C ${m.macros.carbohydratesGrams.toStringAsFixed(0)}g · '
          'G ${m.macros.fatGrams.toStringAsFixed(0)}g',
        ),
        trailing: Text(
          DateFormat.Hm().format(m.consumedAt.toLocal()),
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'BREAKFAST':
        return 'Desayuno';
      case 'LUNCH':
        return 'Almuerzo';
      case 'DINNER':
        return 'Cena';
      case 'SNACK':
        return 'Snack';
      default:
        return type;
    }
  }
}

class _NutritionDashboard {
  final MacroSummary summary;
  final NutritionPlan? plan;
  final List<MealRecord> meals;

  const _NutritionDashboard({
    required this.summary,
    required this.plan,
    required this.meals,
  });
}

class _MacroCard extends StatelessWidget {
  final MacroSummary consumed;
  final MacroSummary target;
  const _MacroCard({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Calorías',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(
                '${consumed.calories.toStringAsFixed(0)} / ${target.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: target.calories == 0
                  ? 0
                  : (consumed.calories / target.calories).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroChip(label: 'Proteína', value: consumed.proteinGrams, target: target.proteinGrams, color: AppColors.coachAccent),
              const SizedBox(width: 8),
              _MacroChip(label: 'Carbos', value: consumed.carbohydratesGrams, target: target.carbohydratesGrams, color: AppColors.warning),
              const SizedBox(width: 8),
              _MacroChip(label: 'Grasas', value: consumed.fatGrams, target: target.fatGrams, color: AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final num value;
  final num target;
  final Color color;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(0)}g',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              'meta ${target.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
