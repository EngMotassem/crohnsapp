import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/mood_model.dart';
import '../../providers/providers.dart';
import '../../config/app_theme.dart';

class MoodCheckinScreen extends StatefulWidget {
  const MoodCheckinScreen({super.key});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  MoodLevel _moodLevel = MoodLevel.neutral;
  StressLevel _stressLevel = StressLevel.none;
  SleepQuality _sleepQuality = SleepQuality.fair;
  double _sleepHours = 7;
  int _anxietyLevel = 0;
  int _depressionLevel = 0;
  bool _feelingIsolated = false;
  bool _impactOnDailyLife = false;
  final List<String> _copingStrategies = [];
  final _notesController = TextEditingController();

  final List<String> _availableCopingStrategies = [
    'Exercise',
    'Meditation',
    'Deep breathing',
    'Talking to someone',
    'Reading',
    'Music',
    'Rest',
    'Journaling',
    'Nature walk',
    'Hobby',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final authProvider = context.read<AuthProvider>();
    final moodProvider = context.read<MoodProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final entry = MoodEntry(
      id: const Uuid().v4(),
      oderId: userId,
      timestamp: DateTime.now(),
      moodLevel: _moodLevel,
      stressLevel: _stressLevel,
      sleepQuality: _sleepQuality,
      sleepHours: _sleepHours,
      anxietyLevel: _anxietyLevel,
      depressionLevel: _depressionLevel,
      feelingIsolated: _feelingIsolated,
      impactOnDailyLife: _impactOnDailyLife,
      copingStrategiesUsed: _copingStrategies,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await moodProvider.addEntry(entry);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood check-in saved'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Check-in'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            Text(
              'Stress Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildStressSelector(),
            const SizedBox(height: 24),
            Text(
              'Sleep Quality',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSleepQualitySelector(),
            const SizedBox(height: 16),
            Text(
              'Hours of Sleep: ${_sleepHours.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _sleepHours,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
            const SizedBox(height: 24),
            _buildSliderSection(
              title: 'Anxiety Level',
              value: _anxietyLevel,
              onChanged: (v) => setState(() => _anxietyLevel = v.round()),
            ),
            _buildSliderSection(
              title: 'Depression Level',
              value: _depressionLevel,
              onChanged: (v) => setState(() => _depressionLevel = v.round()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Feeling Isolated'),
              value: _feelingIsolated,
              onChanged: (v) => setState(() => _feelingIsolated = v),
            ),
            SwitchListTile(
              title: const Text('Impact on Daily Life'),
              subtitle: const Text('Is your condition affecting daily activities?'),
              value: _impactOnDailyLife,
              onChanged: (v) => setState(() => _impactOnDailyLife = v),
            ),
            const SizedBox(height: 24),
            Text(
              'Coping Strategies Used',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCopingStrategies.map((strategy) {
                final isSelected = _copingStrategies.contains(strategy);
                return FilterChip(
                  label: Text(strategy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _copingStrategies.add(strategy);
                      } else {
                        _copingStrategies.remove(strategy);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'How are you coping today?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                child: const Text('Save Check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodLevel.values.map((mood) {
        final isSelected = _moodLevel == mood;
        return GestureDetector(
          onTap: () => setState(() => _moodLevel = mood),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getMoodColor(mood)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: _getMoodColor(mood), width: 2)
                      : null,
                ),
                child: Text(
                  _getMoodEmoji(mood),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _getMoodColor(mood) : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getMoodEmoji(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return '😢';
      case MoodLevel.low:
        return '😔';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.veryGood:
        return '😊';
    }
  }

  Color _getMoodColor(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryLow:
        return Colors.red;
      case MoodLevel.low:
        return Colors.orange;
      case MoodLevel.neutral:
        return Colors.grey;
      case MoodLevel.good:
        return Colors.lightGreen;
      case MoodLevel.veryGood:
        return Colors.green;
    }
  }

  Widget _buildStressSelector() {
    return SegmentedButton<StressLevel>(
      segments: StressLevel.values.map((level) {
        return ButtonSegment(
          value: level,
          label: Text(level.name),
        );
      }).toList(),
      selected: {_stressLevel},
      onSelectionChanged: (v) => setState(() => _stressLevel = v.first),
    );
  }

  Widget _buildSleepQualitySelector() {
    return SegmentedButton<SleepQuality>(
      segments: SleepQuality.values.map((quality) {
        return ButtonSegment(
          value: quality,
          label: Text(quality.name),
        );
      }).toList(),
      selected: {_sleepQuality},
      onSelectionChanged: (v) => setState(() => _sleepQuality = v.first),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForValue(value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(int value) {
    if (value <= 3) return AppTheme.successColor;
    if (value <= 6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
