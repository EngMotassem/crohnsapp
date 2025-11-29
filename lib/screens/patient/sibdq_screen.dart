import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/sibdq_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/sibdq_service.dart';
import '../../config/app_theme.dart';

class SIBDQScreen extends StatefulWidget {
  const SIBDQScreen({super.key});

  @override
  State<SIBDQScreen> createState() => _SIBDQScreenState();
}

class _SIBDQScreenState extends State<SIBDQScreen> {
  final SIBDQService _sibdqService = SIBDQService();
  int _currentQuestion = 0;
  final List<int> _answers = List.filled(10, 0);
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sibdqAssessmentTitle),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / sibdqQuestions.length,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.questionProgress((_currentQuestion + 1).toString(), sibdqQuestions.length.toString()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sibdqQuestions[_currentQuestion].domain,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sibdqQuestions[_currentQuestion].questionText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          sibdqQuestions[_currentQuestion].answerOptions.length,
                      itemBuilder: (context, index) {
                        final option = sibdqQuestions[_currentQuestion]
                            .answerOptions[index];
                        final isSelected = _answers[_currentQuestion] == index + 1;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : null,
                          child: ListTile(
                            title: Text(option),
                            leading: Radio<int>(
                              value: index + 1,
                              groupValue: _answers[_currentQuestion],
                              onChanged: (v) {
                                setState(() {
                                  _answers[_currentQuestion] = v!;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _answers[_currentQuestion] = index + 1;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestion--;
                        });
                      },
                      child: Text(l10n.previous),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _answers[_currentQuestion] == 0
                        ? null
                        : () {
                            if (_currentQuestion < sibdqQuestions.length - 1) {
                              setState(() {
                                _currentQuestion++;
                              });
                            } else {
                              _submitAssessment();
                            }
                          },
                    child: Text(
                      _currentQuestion < sibdqQuestions.length - 1
                          ? l10n.next
                          : l10n.submit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final response = SIBDQResponse(
      id: const Uuid().v4(),
      oderId: userId,
      timestamp: DateTime.now(),
      bowelFrequencyScore: _answers[0],
      looseStoolsScore: _answers[1],
      abdominalPainScore: _answers[2],
      generalWellbeingScore: _answers[3],
      energyLevelScore: _answers[4],
      socialActivityScore: _answers[5],
      emotionalHealthScore: _answers[6],
      sleepQualityScore: _answers[7],
      angerScore: _answers[8],
      embarrassmentScore: _answers[9],
    );

    try {
      await _sibdqService.submitResponse(response);

      if (mounted) {
        _showResultsDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  void _showResultsDialog(SIBDQResponse response) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.assessmentComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourSibdqScore,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getScoreColor(response.totalScore),
                ),
                child: Center(
                  child: Text(
                    '${response.totalScore}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _sibdqService.interpretScore(response.totalScore),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDomainScore(l10n.bowelSymptoms, response.bowelSymptomsDomain, 21),
            _buildDomainScore(l10n.systemicSymptoms, response.systemicSymptomsDomain, 14),
            _buildDomainScore(l10n.socialFunction, response.socialFunctionDomain, 7),
            _buildDomainScore(l10n.emotionalFunction, response.emotionalFunctionDomain, 28),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainScore(String domain, int score, int maxScore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(domain, style: const TextStyle(fontSize: 12)),
          Text(
            '$score / $maxScore',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 60) return AppTheme.successColor;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
