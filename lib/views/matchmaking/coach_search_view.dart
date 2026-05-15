import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/coaches_repository.dart';
import '../common/async_view.dart';
import 'coach_detail_view.dart';

const _kAllSpecialties = <String>[
  'STRENGTH_TRAINING',
  'BODYBUILDING',
  'POWERLIFTING',
  'CALISTHENICS',
  'CROSSFIT',
  'YOGA',
  'MOBILITY',
  'NUTRITION_COACHING',
  'CARDIO',
  'HIIT',
];

String specialtyLabel(String code) {
  switch (code) {
    case 'STRENGTH_TRAINING':
      return 'Fuerza';
    case 'BODYBUILDING':
      return 'Hipertrofia';
    case 'POWERLIFTING':
      return 'Powerlifting';
    case 'CALISTHENICS':
      return 'Calistenia';
    case 'CROSSFIT':
      return 'CrossFit';
    case 'YOGA':
      return 'Yoga';
    case 'MOBILITY':
      return 'Movilidad';
    case 'NUTRITION_COACHING':
      return 'Nutrición';
    case 'CARDIO':
      return 'Cardio';
    case 'HIIT':
      return 'HIIT';
    default:
      return code;
  }
}

class CoachSearchView extends StatefulWidget {
  final int athleteId;
  const CoachSearchView({super.key, required this.athleteId});

  @override
  State<CoachSearchView> createState() => _CoachSearchViewState();
}

class _CoachSearchViewState extends State<CoachSearchView> {
  late Future<List<CoachProfile>> _future;
  final Set<String> _specialties = {};
  double _maxRate = 200;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  void _runSearch() {
    _future = context.read<CoachesRepository>().search(
          specialties: _specialties.toList(),
          maxHourlyRate: _maxRate,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Encuentra tu coach',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Filtra por especialidad y precio.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kAllSpecialties.map((s) {
            final selected = _specialties.contains(s);
            return FilterChip(
              label: Text(specialtyLabel(s)),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _specialties.add(s);
                  } else {
                    _specialties.remove(s);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text('Precio máx por hora: S/ ${_maxRate.toStringAsFixed(0)}'),
        Slider(
          min: 20,
          max: 500,
          divisions: 48,
          value: _maxRate,
          onChanged: (v) => setState(() => _maxRate = v),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Buscar coaches'),
            onPressed: () => setState(_runSearch),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 380,
          child: AsyncView<List<CoachProfile>>(
            future: _future,
            onRetry: () => setState(_runSearch),
            builder: (context, coaches) {
              if (coaches.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.person_search_outlined,
                  title: 'No encontramos coaches',
                  subtitle: 'Prueba ampliando los filtros.',
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: coaches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CoachCard(
                  coach: coaches[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CoachDetailView(
                        coach: coaches[i],
                        athleteId: widget.athleteId,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachProfile coach;
  final VoidCallback onTap;

  const _CoachCard({required this.coach, required this.onTap});

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
                radius: 28,
                backgroundColor: AppColors.coachAccent.withValues(alpha: 0.18),
                child: const Icon(Icons.sports, color: AppColors.coachAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach #${coach.userId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coach.specialties.take(3).map(specialtyLabel).join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 14),
                        const SizedBox(width: 2),
                        Text(coach.averageRating.toStringAsFixed(1)),
                        const SizedBox(width: 8),
                        Text(
                          '${coach.totalReviews} reseñas',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${coach.currency} ${coach.hourlyRate}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    '/ hora',
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
}
