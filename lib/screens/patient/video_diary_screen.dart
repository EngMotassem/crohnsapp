import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/video_diary_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/video_diary_service.dart';
import '../../config/app_theme.dart';

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
        onPressed: () => _showAddVideoDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.record),
      ),
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddYoutubeVideoDiarySheet(),
    );
  }
}

class _VideoDiaryCard extends StatelessWidget {
  final VideoDiary diary;

  const _VideoDiaryCard({required this.diary});

  String? _extractYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final videoId = _extractYoutubeVideoId(diary.videoUrl);
    final thumbnailUrl = videoId != null 
        ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoDiaryPlayerScreen(
                videoUrl: diary.videoUrl,
                title: diary.title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 75,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: thumbnailUrl == null
                    ? const Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: AppTheme.primaryColor,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_filled,
                            size: 40,
                            color: Colors.white,
                          ),
                        ],
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
                      _getCategoryName(context, diary.category),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.smart_display,
                          size: 14,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'YouTube',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: l10n.openInYoutube,
                onPressed: () async {
                  final uri = Uri.tryParse(diary.videoUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddYoutubeVideoDiarySheet extends StatefulWidget {
  const _AddYoutubeVideoDiarySheet();

  @override
  State<_AddYoutubeVideoDiarySheet> createState() => _AddYoutubeVideoDiarySheetState();
}

class _AddYoutubeVideoDiarySheetState extends State<_AddYoutubeVideoDiarySheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final VideoDiaryService _videoDiaryService = VideoDiaryService();
  
  VideoDiaryCategory _category = VideoDiaryCategory.dailyReflection;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
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

  bool _isValidYoutubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) return false;
    
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
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

    final urlText = _youtubeUrlController.text.trim();
    if (urlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterYoutubeUrl),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!_isValidYoutubeUrl(urlText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidYoutubeUrl),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception(l10n.userNotLoggedIn);
      }

      await _videoDiaryService.createVideoDiaryFromYoutube(
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        youtubeUrl: urlText,
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
          _isSaving = false;
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
            const SizedBox(height: 16),
            TextField(
              controller: _youtubeUrlController,
              decoration: InputDecoration(
                labelText: l10n.youtubeUrl,
                prefixIcon: Icon(Icons.smart_display, color: Colors.red[600]),
                hintText: l10n.pasteYoutubeLink,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload your video to YouTube first, then paste the link here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveVideo,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? l10n.saving : l10n.saveVideo),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class VideoDiaryPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoDiaryPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoDiaryPlayerScreen> createState() => _VideoDiaryPlayerScreenState();
}

class _VideoDiaryPlayerScreenState extends State<VideoDiaryPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isError = false;

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final videoId = _extractVideoId(widget.videoUrl);
    
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          mute: false,
          showControls: true,
          showVideoAnnotations: false,
        ),
      );
    } else {
      _isError = true;
      _controller = YoutubePlayerController();
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.isNotEmpty ? widget.title : l10n.videoDiary),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: l10n.openInYoutube,
            onPressed: () async {
              final uri = Uri.tryParse(widget.videoUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: _isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.invalidYoutubeUrl,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.videoUrl);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.openInYoutube),
                  ),
                ],
              ),
            )
          : Center(
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
    );
  }
}
