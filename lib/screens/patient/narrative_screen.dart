import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/narrative_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/narrative_service.dart';
import '../../config/app_theme.dart';

class NarrativeScreen extends StatefulWidget {
  const NarrativeScreen({super.key});

  @override
  State<NarrativeScreen> createState() => _NarrativeScreenState();
}

class _NarrativeScreenState extends State<NarrativeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NarrativeService _narrativeService = NarrativeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: Text(l10n.narratives),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.published),
            Tab(text: l10n.drafts),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NarrativeList(
            stream: _narrativeService.getNarrativesStream(userId),
            emptyMessage: l10n.noNarrativesYet,
          ),
          _NarrativeList(
            stream: _narrativeService.getDraftsStream(userId),
            emptyMessage: l10n.noDrafts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.edit),
        label: Text(l10n.write),
      ),
    );
  }

  void _openEditor(BuildContext context, [Narrative? narrative]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NarrativeEditorScreen(narrative: narrative),
      ),
    );
  }
}

class _NarrativeList extends StatelessWidget {
  final Stream<List<Narrative>> stream;
  final String emptyMessage;

  const _NarrativeList({
    required this.stream,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Narrative>>(
      stream: stream,
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
                  Icons.edit_note,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final narratives = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: narratives.length,
          itemBuilder: (context, index) {
            final narrative = narratives[index];
            return _NarrativeCard(narrative: narrative);
          },
        );
      },
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  final Narrative narrative;

  const _NarrativeCard({required this.narrative});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _NarrativeEditorScreen(narrative: narrative),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      narrative.category.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (narrative.isDraft)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.draft,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                narrative.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                narrative.content.length > 150
                    ? '${narrative.content.substring(0, 150)}...'
                    : narrative.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.article,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${narrative.wordCount} ${l10n.words}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(narrative.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NarrativeEditorScreen extends StatefulWidget {
  final Narrative? narrative;

  const _NarrativeEditorScreen({this.narrative});

  @override
  State<_NarrativeEditorScreen> createState() => _NarrativeEditorScreenState();
}

class _NarrativeEditorScreenState extends State<_NarrativeEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NarrativeService _narrativeService = NarrativeService();
  NarrativeCategory _category = NarrativeCategory.diseaseChallenge;
  bool _isDraft = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.narrative != null) {
      _titleController.text = widget.narrative!.title;
      _contentController.text = widget.narrative!.content;
      _category = widget.narrative!.category;
      _isDraft = widget.narrative!.isDraft;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  Future<void> _save({bool asDraft = true}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTitleNarrative)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final now = DateTime.now();
    final narrative = Narrative(
      id: widget.narrative?.id ?? const Uuid().v4(),
      oderId: userId,
      createdAt: widget.narrative?.createdAt ?? now,
      updatedAt: now,
      title: _titleController.text,
      content: _contentController.text,
      category: _category,
      isDraft: asDraft,
      wordCount: _wordCount,
    );

    try {
      if (widget.narrative != null) {
        await _narrativeService.updateNarrative(narrative);
      } else {
        await _narrativeService.addNarrative(narrative);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft ? l10n.draftSaved : l10n.narrativePublished),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.narrative != null ? l10n.editNarrative : l10n.newNarrative),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(asDraft: true),
            child: Text(l10n.saveDraft),
          ),
          TextButton(
            onPressed: _isSaving ? null : () => _save(asDraft: false),
            child: Text(l10n.publish),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                hintText: l10n.title,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NarrativeCategory>(
              value: _category,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: NarrativeCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 15,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.writeYourStory,
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.article, size: 16, color: AppTheme.textLight),
            const SizedBox(width: 4),
            Text(
              '$_wordCount ${l10n.words}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
