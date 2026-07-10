import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/nutrition_models.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/async_view.dart';

/// Detalle del análisis nutricional con opción de registrar como comida.
class NutritionAnalysisDetailView extends StatefulWidget {
  final int analysisId;
  final int userId;
  const NutritionAnalysisDetailView({
    super.key,
    required this.analysisId,
    required this.userId,
  });

  @override
  State<NutritionAnalysisDetailView> createState() => _NutritionAnalysisDetailViewState();
}

class _NutritionAnalysisDetailViewState extends State<NutritionAnalysisDetailView> {
  late Future<NutritionAnalysis> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<NutritionRepository>().getAnalysis(widget.analysisId);
  }

  Future<void> _logMeal(NutritionAnalysis analysis) async {
    final l10n = AppLocalizations.of(context)!;
    String mealType = 'LUNCH';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.nutritionAnalysis_logMealDialogTitle),
        content: StatefulBuilder(builder: (ctx, setSt) {
          return DropdownButtonFormField<String>(
            initialValue: mealType,
            decoration: InputDecoration(labelText: l10n.nutritionAnalysis_mealTypeLabel),
            items: [
              DropdownMenuItem(value: 'BREAKFAST', child: Text(l10n.nutrition_mealBreakfast)),
              DropdownMenuItem(value: 'LUNCH', child: Text(l10n.nutrition_mealLunch)),
              DropdownMenuItem(value: 'DINNER', child: Text(l10n.nutrition_mealDinner)),
              DropdownMenuItem(value: 'SNACK', child: Text(l10n.nutrition_mealSnack)),
            ],
            onChanged: (v) => setSt(() => mealType = v ?? 'LUNCH'),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.nutritionAnalysis_saveButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<NutritionRepository>().logMeal(LogMealRequest(
            userId: widget.userId,
            mealType: mealType,
            description: _truncateDescription(l10n, analysis.summary),
            macros: analysis.totalMacros,
            consumedAt: DateTime.now(),
            sourceAnalysisId: analysis.id,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nutritionAnalysis_mealLogged)),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  /// El backend limita la descripción de una comida a 500 caracteres; el resumen
  /// de la IA puede ser más largo, así que lo recortamos antes de enviarlo.
  String _truncateDescription(AppLocalizations l10n, String? summary) {
    if (summary == null || summary.trim().isEmpty) {
      return l10n.nutritionAnalysis_defaultDescription;
    }
    return summary.length <= 500 ? summary : '${summary.substring(0, 497)}...';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.nutritionAnalysis_appBarTitle)),
      body: AsyncView<NutritionAnalysis>(
        future: _future,
        onRetry: () => setState(_load),
        builder: (context, analysis) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (analysis.summary != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(analysis.summary!),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${analysis.totalMacros.calories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P ${analysis.totalMacros.proteinGrams.toStringAsFixed(0)}g · '
                      'C ${analysis.totalMacros.carbohydratesGrams.toStringAsFixed(0)}g · '
                      'G ${analysis.totalMacros.fatGrams.toStringAsFixed(0)}g',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.nutritionAnalysis_detectedFoodsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              if (analysis.detectedFoods.isEmpty)
                Text(
                  l10n.nutritionAnalysis_noFoodsDetected,
                  style: const TextStyle(color: AppColors.textSecondary),
                )
              else
                ...analysis.detectedFoods.map((f) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.eco, color: AppColors.success),
                        title: Text(f.foodName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${f.portionGrams.toStringAsFixed(0)}g · '
                          '${f.macros.calories.toStringAsFixed(0)} kcal',
                        ),
                        trailing: f.confidence == null
                            ? null
                            : Text(
                                '${(f.confidence! * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                      ),
                    )),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _logMeal(analysis),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.nutritionAnalysis_logMealButton),
              ),
            ],
          );
        },
      ),
    );
  }
}
