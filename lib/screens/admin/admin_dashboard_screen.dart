import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardOverview,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                l10n.totalUsers,
                'users',
                Icons.people,
                AppTheme.primaryColor,
              ),
                            _buildStatCard(
                              context,
                              l10n.symptomLogs,
                              'symptoms',
                              Icons.healing,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              context,
                              l10n.medicationLogs,
                              'medication_logs',
                              Icons.medication,
                              Colors.green,
                            ),
                            _buildStatCard(
                              context,
                              l10n.dietLogs,
                              'diet_entries',
                              Icons.restaurant,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              context,
                              l10n.moodLogs,
                              'mood_entries',
                              Icons.mood,
                              Colors.purple,
                            ),
              _buildStatCard(
                context,
                l10n.videoDiaries,
                'video_diaries',
                Icons.videocam,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            l10n.recentActivity,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildRecentActivityList(context, l10n),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String collection,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(collection).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final count = snapshot.data?.docs.length ?? 0;
                return Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('lastLoginAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(l10n.noRecentActivity),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final lastLogin = user['lastLoginAt'] as Timestamp?;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (user['displayName'] as String? ?? 'U')[0].toUpperCase(),
                  ),
                ),
                title: Text(user['displayName'] ?? l10n.unknownUser),
                subtitle: Text(user['email'] ?? ''),
                trailing: lastLogin != null
                    ? Text(
                        _formatDate(lastLogin.toDate()),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
