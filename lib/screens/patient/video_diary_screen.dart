import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/video_diary_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/video_diary_service.dart';
import '../../config/app_theme.dart';

const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50MB limit

class VideoDiaryScreen extends StatefulWidget {
  const VideoDiaryScreen({super.key});

  @override
  State<VideoDiaryScreen> createState() => _VideoDiaryScreenState();
}

class _VideoDiaryScreenState extends State<VideoDiaryScreen> {
  final VideoDiaryService _videoDiaryService = VideoDiaryService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      return Scaffold(
        body: Center(child: Text(l10n.pleaseLogIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.videoDiary),
      ),
      body: StreamBuilder<List<VideoDiary>>(
        stream: _videoDiaryService.getVideoDiariesStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 64,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noVideoDiariesYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.recordFirstVideoDiary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final diaries = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              final diary = diaries[index];
              return _VideoDiaryCard(diary: diary);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordDialog(context),
        icon: const Icon(Icons.videocam),
        label: Text(l10n.record),
      ),
    );
  }

  void _showRecordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RecordVideoDiarySheet(),
    );
  }
}

class _VideoDiaryCard extends StatelessWidget {
  final VideoDiary diary;

  const _VideoDiaryCard({required this.diary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diary.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diary.category.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(diary.durationSeconds),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _RecordVideoDiarySheet extends StatefulWidget {
  const _RecordVideoDiarySheet();

  @override
  State<_RecordVideoDiarySheet> createState() => _RecordVideoDiarySheetState();
}

class _RecordVideoDiarySheetState extends State<_RecordVideoDiarySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final VideoDiaryService _videoDiaryService = VideoDiaryService();
  
  VideoDiaryCategory _category = VideoDiaryCategory.dailyReflection;
  XFile? _selectedVideo;
  Uint8List? _videoBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getCategoryName(BuildContext context, VideoDiaryCategory category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case VideoDiaryCategory.dailyReflection:
        return l10n.dailyReflection;
      case VideoDiaryCategory.flareExperience:
        return l10n.flareExperience;
      case VideoDiaryCategory.copingStrategy:
        return l10n.copingStrategy;
      case VideoDiaryCategory.emotionalState:
        return l10n.emotionalState;
      case VideoDiaryCategory.treatmentExperience:
        return l10n.treatmentExperience;
      case VideoDiaryCategory.milestone:
        return l10n.milestone;
      case VideoDiaryCategory.other:
        return l10n.other;
    }
  }

  Future<void> _recordVideo() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        final bytes = await video.readAsBytes();
        if (bytes.length > maxVideoSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoTooLarge('50')),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedVideo = video;
          _videoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorAccessingCamera}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      
      if (video != null) {
        final bytes = await video.readAsBytes();
        if (bytes.length > maxVideoSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoTooLarge('50')),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedVideo = video;
          _videoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorAccessingGallery}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveVideo() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterTitle),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedVideo == null || _videoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectVideo),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception(l10n.userNotLoggedIn);
      }

      await _videoDiaryService.createVideoDiary(
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        videoBytes: _videoBytes!,
        fileName: _selectedVideo!.name,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.videoSaved),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSavingVideo}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newVideoDiary,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VideoDiaryCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: l10n.category,
                prefixIcon: const Icon(Icons.category),
              ),
              items: VideoDiaryCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(_getCategoryName(context, cat)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedVideo != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.videoSelected,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          Text(
                            _selectedVideo!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedVideo = null;
                          _videoBytes = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _saveVideo,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isUploading ? l10n.saving : l10n.saveVideo),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam),
                label: Text(l10n.recordVideo),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickVideoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.chooseFromGallery),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.webVideoNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
