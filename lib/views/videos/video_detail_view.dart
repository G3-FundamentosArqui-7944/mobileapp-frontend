import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/videos_models.dart';
import '../../data/repositories/videos_repository.dart';

/// Detalle del video: hace polling cada 5s hasta que el backend marca COMPLETED/FAILED.
class VideoDetailView extends StatefulWidget {
  final int videoId;
  const VideoDetailView({super.key, required this.videoId});

  @override
  State<VideoDetailView> createState() => _VideoDetailViewState();
}

class _VideoDetailViewState extends State<VideoDetailView> {
  ExerciseVideo? _video;
  String? _error;
  Timer? _poll;
  bool _analyzeTriggered = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_video?.isProcessing ?? true) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final v = await context.read<VideosRepository>().getById(widget.videoId);
      if (!mounted) return;
      setState(() {
        _video = v;
        _error = null;
      });
      // Si el video sigue en UPLOADED, dispara /analyze una sola vez.
      if (!_analyzeTriggered && v.status == 'UPLOADED') {
        _analyzeTriggered = true;
        _triggerAnalyze();
      }
      if (!v.isProcessing) _poll?.cancel();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _triggerAnalyze() async {
    try {
      final updated = await context.read<VideosRepository>().analyze(widget.videoId);
      if (!mounted) return;
      setState(() => _video = updated);
      if (!updated.isProcessing) _poll?.cancel();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Análisis: ${e.message}'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    return Scaffold(
      appBar: AppBar(title: Text(v?.exerciseName ?? 'Análisis de video')),
      body: v == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!, style: const TextStyle(color: AppColors.error)),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _StatusBanner(video: v),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.exerciseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (v.description != null) ...[
                            const SizedBox(height: 4),
                            Text(v.description!,
                                style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Tamaño: ${(v.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (v.analysis != null) ...[
                    const SizedBox(height: 16),
                    _AnalysisSection(analysis: v.analysis!),
                  ],
                  if (v.isFailed && v.failureReason != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          v.failureReason!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final ExerciseVideo video;
  const _StatusBanner({required this.video});

  @override
  Widget build(BuildContext context) {
    final color = video.isCompleted
        ? AppColors.success
        : video.isFailed
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            video.isCompleted
                ? Icons.check_circle
                : video.isFailed
                    ? Icons.error_outline
                    : Icons.hourglass_top,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              video.isCompleted
                  ? 'Análisis completado'
                  : video.isFailed
                      ? 'No se pudo analizar el video'
                      : 'Procesando análisis con IA…',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  final VideoAnalysis analysis;
  const _AnalysisSection({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Resultado IA',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            if (analysis.overallScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${analysis.overallScore!.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (analysis.summary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(analysis.summary!),
            ),
          ),
        const SizedBox(height: 8),
        ...analysis.feedbackItems.map((f) => Card(
              child: ListTile(
                leading: Icon(
                  Icons.flag,
                  color: _severityColor(f.severity),
                ),
                title: Text(f.aspect, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(f.message),
                trailing: f.timestampSeconds == null
                    ? null
                    : Text(
                        '${f.timestampSeconds}s',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
              ),
            )),
      ],
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.error;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
