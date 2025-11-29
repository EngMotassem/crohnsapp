import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/symptom_model.dart';
import '../../providers/providers.dart';
import '../../config/app_theme.dart';

class SymptomTrackingScreen extends StatefulWidget {
  const SymptomTrackingScreen({super.key});

  @override
  State<SymptomTrackingScreen> createState() => _SymptomTrackingScreenState();
}

class _SymptomTrackingScreenState extends State<SymptomTrackingScreen> {
  int _painLevel = 0;
  int _stoolFrequency = 0;
  int _urgencyLevel = 0;
  int _fatigueLevel = 0;
  bool _hasBlood = false;
  bool _hasMucus = false;
  bool _hasNausea = false;
  bool _hasVomiting = false;
  bool _hasFever = false;
  bool _hasJointPain = false;
  bool _hasSkinIssues = false;
  bool _hasEyeIssues = false;
  bool _isFlare = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final authProvider = context.read<AuthProvider>();
    final symptomProvider = context.read<SymptomProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final entry = SymptomEntry(
      id: const Uuid().v4(),
      oderId: userId,
      timestamp: DateTime.now(),
      painLevel: _painLevel,
      stoolFrequency: _stoolFrequency,
      urgencyLevel: _urgencyLevel,
      fatigueLevel: _fatigueLevel,
      hasBlood: _hasBlood,
      hasMucus: _hasMucus,
      hasNausea: _hasNausea,
      hasVomiting: _hasVomiting,
      hasFever: _hasFever,
      hasJointPain: _hasJointPain,
      hasSkinIssues: _hasSkinIssues,
      hasEyeIssues: _hasEyeIssues,
      isFlare: _isFlare,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await symptomProvider.addEntry(entry);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptoms logged successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(symptomProvider.error ?? 'Failed to save'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Symptoms'),
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
            _buildSliderSection(
              title: 'Pain Level',
              value: _painLevel,
              onChanged: (v) => setState(() => _painLevel = v.round()),
              icon: Icons.healing,
            ),
            _buildSliderSection(
              title: 'Stool Frequency (times today)',
              value: _stoolFrequency,
              max: 20,
              onChanged: (v) => setState(() => _stoolFrequency = v.round()),
              icon: Icons.repeat,
            ),
            _buildSliderSection(
              title: 'Urgency Level',
              value: _urgencyLevel,
              onChanged: (v) => setState(() => _urgencyLevel = v.round()),
              icon: Icons.warning_amber,
            ),
            _buildSliderSection(
              title: 'Fatigue Level',
              value: _fatigueLevel,
              onChanged: (v) => setState(() => _fatigueLevel = v.round()),
              icon: Icons.battery_alert,
            ),
            const SizedBox(height: 24),
            Text(
              'Additional Symptoms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSymptomChip('Blood in stool', _hasBlood,
                    (v) => setState(() => _hasBlood = v)),
                _buildSymptomChip(
                    'Mucus', _hasMucus, (v) => setState(() => _hasMucus = v)),
                _buildSymptomChip(
                    'Nausea', _hasNausea, (v) => setState(() => _hasNausea = v)),
                _buildSymptomChip('Vomiting', _hasVomiting,
                    (v) => setState(() => _hasVomiting = v)),
                _buildSymptomChip(
                    'Fever', _hasFever, (v) => setState(() => _hasFever = v)),
                _buildSymptomChip('Joint pain', _hasJointPain,
                    (v) => setState(() => _hasJointPain = v)),
                _buildSymptomChip('Skin issues', _hasSkinIssues,
                    (v) => setState(() => _hasSkinIssues = v)),
                _buildSymptomChip('Eye issues', _hasEyeIssues,
                    (v) => setState(() => _hasEyeIssues = v)),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Mark as Flare'),
              subtitle: const Text('Is this a flare-up episode?'),
              value: _isFlare,
              onChanged: (v) => setState(() => _isFlare = v),
              activeColor: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any other symptoms or observations...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Consumer<SymptomProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveEntry,
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Symptoms'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required int value,
    required ValueChanged<double> onChanged,
    required IconData icon,
    int max = 10,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForValue(value, max),
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
              max: max.toDouble(),
              divisions: max,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('None', style: Theme.of(context).textTheme.bodySmall),
                Text('Severe', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(int value, int max) {
    final ratio = value / max;
    if (ratio <= 0.3) return AppTheme.successColor;
    if (ratio <= 0.6) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Widget _buildSymptomChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }
}
