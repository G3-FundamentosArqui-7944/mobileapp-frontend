import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
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
  bool _analyzing = false;

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
    if (_analyzing) return;
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.nutrition_takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.nutrition_chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _analyzing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.nutrition_analyzingSnackbar),
        duration: const Duration(seconds: 30),
      ),
    );
    try {
      final analysis = await context.read<NutritionRepository>().analyzeImage(
            userId: widget.userId,
            image: File(picked.path),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nutrition_analyzeFailed(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = context.watch<LocaleController>().intlLocaleCode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzing ? null : _pickAndAnalyze,
        icon: _analyzing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.restaurant_menu),
        label: Text(_analyzing ? l10n.nutrition_analyzingButton : l10n.nutrition_analyzeButton),
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
                Text(
                  l10n.nutrition_todayTitle,
                  style: const TextStyle(
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
                  SectionHeader(title: l10n.nutrition_activePlanSection),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.flag, color: AppColors.accent),
                      title: Text(data.plan!.name),
                      subtitle: Text(
                        l10n.nutrition_planUntil(DateFormat('d MMM y', intlLocale).format(
                            data.plan!.endDate ?? DateTime.now().add(const Duration(days: 30)))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SectionHeader(title: l10n.nutrition_todaysMealsSection),
                if (data.meals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.nutrition_noMealsLogged,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...data.meals.map((m) => _buildMealCard(l10n, m)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMealCard(AppLocalizations l10n, MealRecord m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.accent,
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          m.description ?? _mealLabel(l10n, m.mealType),
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

  String _mealLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'BREAKFAST':
        return l10n.nutrition_mealBreakfast;
      case 'LUNCH':
        return l10n.nutrition_mealLunch;
      case 'DINNER':
        return l10n.nutrition_mealDinner;
      case 'SNACK':
        return l10n.nutrition_mealSnack;
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.nutrition_caloriesLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
              _MacroChip(
                label: l10n.nutrition_proteinLabel,
                value: consumed.proteinGrams,
                target: target.proteinGrams,
                color: AppColors.coachAccent,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: l10n.nutrition_carbsLabel,
                value: consumed.carbohydratesGrams,
                target: target.carbohydratesGrams,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              _MacroChip(
                label: l10n.nutrition_fatLabel,
                value: consumed.fatGrams,
                target: target.fatGrams,
                color: AppColors.accent,
              ),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.nutrition_targetLabel(target.toStringAsFixed(0)),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
