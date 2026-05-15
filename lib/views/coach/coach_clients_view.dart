import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/matchmaking_models.dart';
import '../../data/repositories/connection_requests_repository.dart';
import '../common/async_view.dart';

/// Coach: clientes activos + solicitudes pendientes (aprobar / rechazar).
class CoachClientsView extends StatefulWidget {
  final int coachId;
  const CoachClientsView({super.key, required this.coachId});

  @override
  State<CoachClientsView> createState() => _CoachClientsViewState();
}

class _CoachClientsViewState extends State<CoachClientsView> {
  late Future<List<ConnectionRequest>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ConnectionRequestsRepository>().byCoach(widget.coachId);
  }

  Future<void> _respond(ConnectionRequest r, bool approve) async {
    try {
      await context.read<ConnectionRequestsRepository>().respond(
            r.id,
            RespondConnectionRequest(approve: approve),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Cliente aceptado' : 'Solicitud rechazada'),
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
    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: AsyncView<List<ConnectionRequest>>(
        future: _future,
        onRetry: () => setState(_load),
        builder: (context, requests) {
          if (requests.isEmpty) {
            return const EmptyStateView(
              icon: Icons.group_add_outlined,
              title: 'Aún no tienes clientes',
              subtitle: 'Cuando un atleta te solicite, aparecerá aquí.',
            );
          }
          final pending = requests.where((r) => r.status == 'PENDING').toList();
          final accepted = requests.where((r) => r.status == 'APPROVED' || r.status == 'ACCEPTED').toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (pending.isNotEmpty) ...[
                const Text(
                  'Solicitudes pendientes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...pending.map((r) => _RequestCard(
                      request: r,
                      onAccept: () => _respond(r, true),
                      onReject: () => _respond(r, false),
                    )),
                const SizedBox(height: 20),
              ],
              const Text(
                'Mis clientes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (accepted.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Todavía no tienes clientes aceptados.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...accepted.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.athleteAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('Atleta #${r.athleteId}'),
                        subtitle: r.message == null ? null : Text(r.message!),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ConnectionRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.warning,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atleta #${request.athleteId}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (request.message != null && request.message!.isNotEmpty)
                        Text(
                          request.message!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
