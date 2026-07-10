import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/membership_models.dart';
import '../../data/repositories/membership_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_controller.dart';
import '../common/async_view.dart';
import '../common/section_header.dart';

/// Vista de membresía: estado actual + planes disponibles + suscribirse.
class MembershipView extends StatefulWidget {
  final int userId;
  const MembershipView({super.key, required this.userId});

  @override
  State<MembershipView> createState() => _MembershipViewState();
}

class _MembershipViewState extends State<MembershipView> {
  late Future<_MembershipData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<MembershipRepository>();
    _future = () async {
      final plans = await repo.listPlans(onlyActive: true);
      final status = await repo.membershipStatus(widget.userId);
      return _MembershipData(plans: plans, status: status);
    }();
  }

  Future<void> _subscribe(MembershipPlan plan) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.membership_subscribeDialogTitle(plan.name)),
        content: Text(
          l10n.membership_subscribeDialogMessage(
            plan.billingPeriod.toLowerCase(),
            plan.currency,
            plan.priceAmount.toStringAsFixed(2),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.membership_subscribeButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<MembershipRepository>().subscribe(
            CreateSubscriptionRequest(userId: widget.userId, planCode: plan.code),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.membership_subscriptionCreated)),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.membership_appBarTitle)),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<_MembershipData>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, data) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StatusBanner(status: data.status),
                const SizedBox(height: 24),
                SectionHeader(title: l10n.membership_availablePlansSection),
                if (data.plans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.membership_noActivePlans,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...data.plans.map((p) => _PlanCard(plan: p, onSubscribe: () => _subscribe(p))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MembershipData {
  final List<MembershipPlan> plans;
  final MembershipValidation status;
  const _MembershipData({required this.plans, required this.status});
}

class _StatusBanner extends StatelessWidget {
  final MembershipValidation status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = context.watch<LocaleController>().intlLocaleCode;
    final active = status.active;
    final color = active ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.workspace_premium : Icons.lock_outline, size: 32, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? l10n.membership_activeStatus : l10n.membership_inactiveStatus,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (active && status.planCode != null)
                  Text(
                    l10n.membership_planValidUntil(
                      status.planCode!,
                      status.currentPeriodEnd == null
                          ? '—'
                          : DateFormat('d MMM y', intlLocale).format(status.currentPeriodEnd!),
                    ),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final VoidCallback onSubscribe;
  const _PlanCard({required this.plan, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Text(
                  '${plan.currency} ${plan.priceAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.billingPeriod,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (plan.description != null) ...[
              const SizedBox(height: 8),
              Text(plan.description!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSubscribe,
              child: Text(AppLocalizations.of(context)!.membership_subscribeToPlanButton),
            ),
          ],
        ),
      ),
    );
  }
}
