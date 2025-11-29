import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final authProvider = context.read<AuthProvider>();
    await authProvider.updatePrivacySettings(_settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings saved'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
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
                          'About Privacy Levels',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyLevelInfo(
                      'Private',
                      'Only you can see this data',
                      Icons.lock,
                    ),
                    _buildPrivacyLevelInfo(
                      'Anonymized for Research',
                      'Researchers can access anonymized data',
                      Icons.science,
                    ),
                    _buildPrivacyLevelInfo(
                      'Shared with Clinician',
                      'Your clinician can view this data',
                      Icons.medical_services,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Data Privacy Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPrivacySetting(
              'Symptoms',
              'Pain, stool frequency, urgency, fatigue',
              Icons.healing,
              'symptoms',
              _settings.symptomsPrivacy,
            ),
            _buildPrivacySetting(
              'Medications',
              'Medication logs and adherence',
              Icons.medication,
              'medications',
              _settings.medicationsPrivacy,
            ),
            _buildPrivacySetting(
              'Diet',
              'Food logs and trigger tracking',
              Icons.restaurant,
              'diet',
              _settings.dietPrivacy,
            ),
            _buildPrivacySetting(
              'Mood',
              'Mood check-ins and wellbeing',
              Icons.mood,
              'mood',
              _settings.moodPrivacy,
            ),
            _buildPrivacySetting(
              'Video Diaries',
              'Video recordings and reflections',
              Icons.videocam,
              'videoDiary',
              _settings.videoDiaryPrivacy,
            ),
            _buildPrivacySetting(
              'Narratives',
              'Written stories and experiences',
              Icons.edit_note,
              'narratives',
              _settings.narrativesPrivacy,
            ),
            _buildPrivacySetting(
              'SIBDQ Assessments',
              'Quality of life questionnaires',
              Icons.assignment,
              'proms',
              _settings.promsPrivacy,
            ),
            const SizedBox(height: 32),
            if (_hasChanges)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Changes'),
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
              segments: const [
                ButtonSegment(
                  value: PrivacyLevel.private,
                  label: Text('Private'),
                  icon: Icon(Icons.lock),
                ),
                ButtonSegment(
                  value: PrivacyLevel.anonymizedForResearch,
                  label: Text('Research'),
                  icon: Icon(Icons.science),
                ),
                ButtonSegment(
                  value: PrivacyLevel.sharedWithClinician,
                  label: Text('Clinician'),
                  icon: Icon(Icons.medical_services),
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
