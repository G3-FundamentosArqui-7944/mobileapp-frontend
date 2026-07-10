import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/api/api_client.dart';
import '../../data/models/videos_models.dart';
import '../../data/repositories/videos_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/async_view.dart';
import 'video_detail_view.dart';

/// Lista de videos del atleta + acción para subir uno nuevo.
class VideoAnalysisView extends StatefulWidget {
  final int userId;
  const VideoAnalysisView({super.key, required this.userId});

  @override
  State<VideoAnalysisView> createState() => _VideoAnalysisViewState();
}

class _VideoAnalysisViewState extends State<VideoAnalysisView> {
  late Future<List<ExerciseVideo>> _future;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<VideosRepository>().byUser(widget.userId);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked == null || !mounted) return;

    final exerciseCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.videoAnalysis_videoDetailsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciseCtrl,
              decoration: InputDecoration(
                labelText: l10n.videoAnalysis_exerciseLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionCtrl,
              decoration: InputDecoration(labelText: l10n.videoAnalysis_notesLabel),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.videoAnalysis_uploadButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _uploading = true);
    try {
      final video = await context.read<VideosRepository>().upload(
            userId: widget.userId,
            exerciseName: exerciseCtrl.text.trim().isEmpty
                ? l10n.videoAnalysis_defaultExerciseName
                : exerciseCtrl.text.trim(),
            description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
            file: File(picked.path),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.videoAnalysis_uploadedProcessing)),
      );
      // El detail view se encarga de disparar /analyze cuando vea el video en UPLOADED.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoDetailView(videoId: video.id),
        ),
      );
      setState(_load);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : () => _showUploadSheet(),
        icon: _uploading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : const Icon(Icons.add),
        label: Text(_uploading ? l10n.videoAnalysis_uploadingButton : l10n.videoAnalysis_newVideoButton),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: AsyncView<List<ExerciseVideo>>(
          future: _future,
          onRetry: () => setState(_load),
          builder: (context, videos) {
            if (videos.isEmpty) {
              return EmptyStateView(
                icon: Icons.videocam_outlined,
                title: l10n.videoAnalysis_emptyTitle,
                subtitle: l10n.videoAnalysis_emptySubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _VideoCard(
                video: videos[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VideoDetailView(videoId: videos[i].id)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUploadSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.videoAnalysis_recordWithCamera),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(l10n.nutrition_chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final ExerciseVideo video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = video.isCompleted
        ? AppColors.success
        : video.isFailed
            ? AppColors.error
            : AppColors.warning;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.play_arrow, color: color),
        ),
        title: Text(video.exerciseName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(video.status),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
