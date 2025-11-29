import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late PrivacySettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _settings = authProvider.user?.privacySettings ?? PrivacySettings();
  }

  void _updateSetting(String field, PrivacyLevel level) {
    setState(() {
      _hasChanges = true;
      switch (field) {
        case 'symptoms':
          _settings = _settings.copyWith(symptomsPrivacy: level);
          break;
        case 'medications':
          _settings = _settings.copyWith(medicationsPrivacy: level);
          break;
        case 'diet':
          _settings = _settings.copyWith(dietPrivacy: level);
          break;
        case 'mood':
          _settings = _settings.copyWith(moodPrivacy: level);
          break;
        case 'videoDiary':
          _settings = _settings.copyWith(videoDiaryPrivacy: level);
          break;
        case 'narratives':
          _settings = _settings.copyWith(narrativesPrivacy: level);
          break;
        case 'proms':
          _settings = _settings.copyWith(promsPrivacy: level);
          break;
      }
    });
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    await authProvider.updatePrivacySettings(_settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.privacySettingsSaved),
          backgroundColor: AppTheme.successColor,
        ),
      );
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacySettingsTitle),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          l10n.aboutPrivacyLevels,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyLevelInfo(
                      l10n.private,
                      l10n.onlyYouCanSee,
                      Icons.lock,
                    ),
                    _buildPrivacyLevelInfo(
                      l10n.anonymizedForResearch,
                      l10n.researchersCanAccess,
                      Icons.science,
                    ),
                    _buildPrivacyLevelInfo(
                      l10n.sharedWithClinician,
                      l10n.clinicianCanView,
                      Icons.medical_services,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.dataPrivacySettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPrivacySetting(
              l10n.symptomsPrivacy,
              l10n.symptomsPrivacyDesc,
              Icons.healing,
              'symptoms',
              _settings.symptomsPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.medicationsPrivacy,
              l10n.medicationsPrivacyDesc,
              Icons.medication,
              'medications',
              _settings.medicationsPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.dietPrivacy,
              l10n.dietPrivacyDesc,
              Icons.restaurant,
              'diet',
              _settings.dietPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.moodPrivacy,
              l10n.moodPrivacyDesc,
              Icons.mood,
              'mood',
              _settings.moodPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.videoDiaryPrivacy,
              l10n.videoDiaryPrivacyDesc,
              Icons.videocam,
              'videoDiary',
              _settings.videoDiaryPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.narrativesPrivacy,
              l10n.narrativesPrivacyDesc,
              Icons.edit_note,
              'narratives',
              _settings.narrativesPrivacy,
              l10n,
            ),
            _buildPrivacySetting(
              l10n.sibdqPrivacy,
              l10n.sibdqPrivacyDesc,
              Icons.assignment,
              'proms',
              _settings.promsPrivacy,
              l10n,
            ),
            const SizedBox(height: 32),
            if (_hasChanges)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: Text(l10n.saveChanges),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyLevelInfo(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySetting(
    String title,
    String description,
    IconData icon,
    String field,
    PrivacyLevel currentLevel,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<PrivacyLevel>(
              segments: [
                ButtonSegment(
                  value: PrivacyLevel.private,
                  label: Text(l10n.private),
                  icon: const Icon(Icons.lock),
                ),
                ButtonSegment(
                  value: PrivacyLevel.anonymizedForResearch,
                  label: Text(l10n.research),
                  icon: const Icon(Icons.science),
                ),
                ButtonSegment(
                  value: PrivacyLevel.sharedWithClinician,
                  label: Text(l10n.clinician),
                  icon: const Icon(Icons.medical_services),
                ),
              ],
              selected: {currentLevel},
              onSelectionChanged: (selected) {
                _updateSetting(field, selected.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
