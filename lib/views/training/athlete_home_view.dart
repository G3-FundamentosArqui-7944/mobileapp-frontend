import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/training_models.dart';
import '../../data/repositories/training_repository.dart';
import '../common/async_view.dart';
import '../common/section_header.dart';
import '../matchmaking/coach_search_view.dart';
import '../nutrition/nutrition_view.dart';
import '../videos/video_analysis_view.dart';
import 'workout_list_view.dart';

/// Dashboard del atleta: analytics + accesos rápidos a sus features.
class AthleteHomeView extends StatefulWidget {
  final AuthenticatedUser user;
  const AthleteHomeView({super.key, required this.user});

  @override
  State<AthleteHomeView> createState() => _AthleteHomeViewState();
}

class _AthleteHomeViewState extends State<AthleteHomeView> {
  late Future<TrainingAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _analyticsFuture = context.read<TrainingRepository>().analyticsForUser(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${widget.user.firstName ?? 'atleta'} 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aquí está tu progreso de entrenamiento.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: AsyncView<TrainingAnalytics>(
              future: _analyticsFuture,
              onRetry: () => setState(_load),
              builder: (context, analytics) => _AnalyticsGrid(analytics: analytics),
            ),
          ),
          const SizedBox(height: 12),
          const SectionHeader(
            title: 'Atajos',
            subtitle: 'Las acciones que más usas',
          ),
          _ShortcutTile(
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
            title: 'Mis entrenamientos',
            subtitle: 'Inicia una sesión y registra tus ejercicios',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WorkoutListView(userId: widget.user.id)),
            ),
          ),
          _ShortcutTile(
            icon: Icons.videocam_rounded,
            color: AppColors.accent,
            title: 'Subir un video',
            subtitle: 'Recibe feedback técnico de IA',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoAnalysisView(userId: widget.user.id)),
            ),
          ),
          _ShortcutTile(
            icon: Icons.restaurant_rounded,
            color: AppColors.warning,
            title: 'Registrar comida',
            subtitle: 'Foto del plato → calorías y macros',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NutritionView(userId: widget.user.id)),
            ),
          ),
          _ShortcutTile(
            icon: Icons.search_rounded,
            color: AppColors.coachAccent,
            title: 'Encontrar coach',
            subtitle: 'Filtra por especialidad y precio',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CoachSearchView(athleteId: widget.user.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final TrainingAnalytics analytics;
  const _AnalyticsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _MetricCard(
        label: 'Entrenamientos',
        value: analytics.totalWorkouts.toString(),
        icon: Icons.fitness_center,
        color: AppColors.primary,
      ),
      _MetricCard(
        label: 'Completados',
        value: analytics.completedWorkouts.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _MetricCard(
        label: 'Volumen total',
        value: analytics.totalVolume.toString(),
        icon: Icons.bolt,
        color: AppColors.coachAccent,
      ),
      _MetricCard(
        label: 'Tasa éxito',
        value: '${(analytics.completionRate * 100).toStringAsFixed(0)}%',
        icon: Icons.trending_up,
        color: AppColors.accent,
      ),
    ];
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
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
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ShortcutTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
