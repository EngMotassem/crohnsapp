import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(
          content: Text(l10n.symptomsLoggedSuccess),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(symptomProvider.error ?? l10n.failedToSave),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logSymptoms),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSliderSection(
              title: l10n.painLevel,
              value: _painLevel,
              onChanged: (v) => setState(() => _painLevel = v.round()),
              icon: Icons.healing,
              l10n: l10n,
            ),
            _buildSliderSection(
              title: l10n.stoolFrequencyTimesToday,
              value: _stoolFrequency,
              max: 20,
              onChanged: (v) => setState(() => _stoolFrequency = v.round()),
              icon: Icons.repeat,
              l10n: l10n,
            ),
            _buildSliderSection(
              title: l10n.urgencyLevel,
              value: _urgencyLevel,
              onChanged: (v) => setState(() => _urgencyLevel = v.round()),
              icon: Icons.warning_amber,
              l10n: l10n,
            ),
            _buildSliderSection(
              title: l10n.fatigueLevel,
              value: _fatigueLevel,
              onChanged: (v) => setState(() => _fatigueLevel = v.round()),
              icon: Icons.battery_alert,
              l10n: l10n,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.additionalSymptoms,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSymptomChip(l10n.bloodInStool, _hasBlood,
                    (v) => setState(() => _hasBlood = v)),
                _buildSymptomChip(
                    l10n.mucus, _hasMucus, (v) => setState(() => _hasMucus = v)),
                _buildSymptomChip(
                    l10n.nausea, _hasNausea, (v) => setState(() => _hasNausea = v)),
                _buildSymptomChip(l10n.vomiting, _hasVomiting,
                    (v) => setState(() => _hasVomiting = v)),
                _buildSymptomChip(
                    l10n.fever, _hasFever, (v) => setState(() => _hasFever = v)),
                _buildSymptomChip(l10n.jointPain, _hasJointPain,
                    (v) => setState(() => _hasJointPain = v)),
                _buildSymptomChip(l10n.skinIssues, _hasSkinIssues,
                    (v) => setState(() => _hasSkinIssues = v)),
                _buildSymptomChip(l10n.eyeIssues, _hasEyeIssues,
                    (v) => setState(() => _hasEyeIssues = v)),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(l10n.markAsFlare),
              subtitle: Text(l10n.isThisFlareUp),
              value: _isFlare,
              onChanged: (v) => setState(() => _isFlare = v),
              activeColor: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.additionalNotes,
                hintText: l10n.anyOtherSymptoms,
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
                        : Text(l10n.saveSymptoms),
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
    required AppLocalizations l10n,
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
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
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
                Text(l10n.noneSeverity, style: Theme.of(context).textTheme.bodySmall),
                Text(l10n.severeSeverity, style: Theme.of(context).textTheme.bodySmall),
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
