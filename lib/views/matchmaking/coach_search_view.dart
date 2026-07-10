import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/coaches_repository.dart';
import '../../l10n/generated/app_localizations.dart';
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

String specialtyLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'STRENGTH_TRAINING':
      return l10n.specialty_strengthTraining;
    case 'BODYBUILDING':
      return l10n.specialty_bodybuilding;
    case 'POWERLIFTING':
      return l10n.specialty_powerlifting;
    case 'CALISTHENICS':
      return l10n.specialty_calisthenics;
    case 'CROSSFIT':
      return l10n.specialty_crossfit;
    case 'YOGA':
      return l10n.specialty_yoga;
    case 'MOBILITY':
      return l10n.specialty_mobility;
    case 'NUTRITION_COACHING':
      return l10n.specialty_nutritionCoaching;
    case 'CARDIO':
      return l10n.specialty_cardio;
    case 'HIIT':
      return l10n.specialty_hiit;
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachSearch_appBarTitle)),
      body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const SizedBox(height: 4),
        Text(
          l10n.coachSearch_subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kAllSpecialties.map((s) {
            final selected = _specialties.contains(s);
            return FilterChip(
              label: Text(specialtyLabel(l10n, s)),
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
        Text(l10n.coachSearch_maxRateLabel(_maxRate.toStringAsFixed(0))),
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
            label: Text(l10n.coachSearch_searchButton),
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
                return EmptyStateView(
                  icon: Icons.person_search_outlined,
                  title: l10n.coachSearch_emptyTitle,
                  subtitle: l10n.coachSearch_emptySubtitle,
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
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final CoachProfile coach;
  final VoidCallback onTap;

  const _CoachCard({required this.coach, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.coachSearch_coachIdLabel(coach.userId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coach.specialties.take(3).map((s) => specialtyLabel(l10n, s)).join(' · '),
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
                          l10n.coachSearch_reviewsCount(coach.totalReviews),
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
                  Text(
                    l10n.coachSearch_perHourSuffix,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
