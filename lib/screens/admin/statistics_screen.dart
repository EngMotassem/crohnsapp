import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '7days';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.statisticsAndAnalytics,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: [
                  DropdownMenuItem(value: '7days', child: Text(l10n.last7Days)),
                  DropdownMenuItem(value: '30days', child: Text(l10n.last30Days)),
                  DropdownMenuItem(value: '90days', child: Text(l10n.last90Days)),
                  DropdownMenuItem(value: 'all', child: Text(l10n.allTime)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUserStatistics(context, l10n),
          const SizedBox(height: 24),
          _buildActivityStatistics(context, l10n),
          const SizedBox(height: 24),
          _buildRoleDistribution(context, l10n),
        ],
      ),
    );
  }

  Widget _buildUserStatistics(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.userStatistics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];
                final now = DateTime.now();
                final periodStart = _getPeriodStart(now);

                int totalUsers = users.length;
                int newUsers = 0;
                int activeUsers = 0;

                for (final doc in users) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final lastLogin = (data['lastLoginAt'] as Timestamp?)?.toDate();

                  if (createdAt != null && createdAt.isAfter(periodStart)) {
                    newUsers++;
                  }
                  if (lastLogin != null && lastLogin.isAfter(periodStart)) {
                    activeUsers++;
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        l10n.totalUsers,
                        totalUsers.toString(),
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        l10n.newUsers,
                        newUsers.toString(),
                        Icons.person_add,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        l10n.activeUsers,
                        activeUsers.toString(),
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStatistics(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activityStatistics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                                Expanded(
                                  child: _buildCollectionStatCard(
                                    context,
                                    l10n.symptomLogs,
                                    'symptoms',
                                    Icons.healing,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildCollectionStatCard(
                                    context,
                                    l10n.medicationLogs,
                                    'medication_logs',
                                    Icons.medication,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildCollectionStatCard(
                                    context,
                                    l10n.dietLogs,
                                    'diet_entries',
                                    Icons.restaurant,
                                    Colors.blue,
                                  ),
                                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                                Expanded(
                                  child: _buildCollectionStatCard(
                                    context,
                                    l10n.moodLogs,
                                    'mood_entries',
                                    Icons.mood,
                                    Colors.purple,
                                  ),
                                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCollectionStatCard(
                    context,
                    l10n.videoDiaries,
                    'video_diaries',
                    Icons.videocam,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCollectionStatCard(
                    context,
                    l10n.narratives,
                    'narratives',
                    Icons.edit_note,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistribution(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.roleDistribution,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];
                int patients = 0;
                int clinicians = 0;
                int researchers = 0;
                int admins = 0;

                for (final doc in users) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] as String? ?? 'patient';

                  switch (role) {
                    case 'patient':
                      patients++;
                      break;
                    case 'clinician':
                      clinicians++;
                      break;
                    case 'researcher':
                      researchers++;
                      break;
                    case 'admin':
                      admins++;
                      break;
                  }
                }

                final total = users.length;

                return Column(
                  children: [
                    _buildRoleBar(context, l10n.patient, patients, total, AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    _buildRoleBar(context, l10n.clinicianRole, clinicians, total, Colors.blue),
                    const SizedBox(height: 12),
                    _buildRoleBar(context, l10n.researcher, researchers, total, Colors.green),
                    const SizedBox(height: 12),
                    _buildRoleBar(context, l10n.admin, admins, total, Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCollectionStatCard(
    BuildContext context,
    String title,
    String collection,
    IconData icon,
    Color color,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final periodStart = _getPeriodStart(DateTime.now());

        int periodCount = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null && createdAt.isAfter(periodStart)) {
              periodCount++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '+$periodCount',
                style: TextStyle(color: Colors.green[700], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: Text(
            '$count (${(percentage * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  DateTime _getPeriodStart(DateTime now) {
    switch (_selectedPeriod) {
      case '7days':
        return now.subtract(const Duration(days: 7));
      case '30days':
        return now.subtract(const Duration(days: 30));
      case '90days':
        return now.subtract(const Duration(days: 90));
      default:
        return DateTime(2000);
    }
  }
}
