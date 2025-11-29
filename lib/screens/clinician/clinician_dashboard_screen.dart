import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/clinician_service.dart';
import '../../config/app_theme.dart';

class ClinicianDashboardScreen extends StatefulWidget {
  const ClinicianDashboardScreen({super.key});

  @override
  State<ClinicianDashboardScreen> createState() =>
      _ClinicianDashboardScreenState();
}

class _ClinicianDashboardScreenState extends State<ClinicianDashboardScreen> {
  final ClinicianService _clinicianService = ClinicianService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PatientsTab(),
          _AnalyticsTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _PatientsTab extends StatelessWidget {
  const _PatientsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final clinicianId = authProvider.user?.id;

    if (clinicianId == null) {
      return const Center(child: Text('Please log in'));
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'View and manage patient data',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: ClinicianService().getPatientsWithSharedData(clinicianId),
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
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients with shared data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patients need to share their data with you',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final patients = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _PatientCard(patient: patient);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final UserModel patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _PatientDetailScreen(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  patient.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      patient.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientDetailScreen extends StatefulWidget {
  final UserModel patient;

  const _PatientDetailScreen({required this.patient});

  @override
  State<_PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<_PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClinicianService _clinicianService = ClinicianService();
  Map<String, dynamic>? _overview;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOverview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    final overview =
        await _clinicianService.getPatientOverview(widget.patient.id);
    setState(() => _overview = overview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Symptoms'),
            Tab(text: 'Mood'),
            Tab(text: 'Diet'),
            Tab(text: 'SIBDQ'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSymptomsTab(),
                _buildMoodTab(),
                _buildDietTab(),
                _buildSIBDQTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _selectDate(true),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('to'),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _selectDate(false),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Widget _buildOverviewTab() {
    if (_overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Symptom Entries',
                  value: '${_overview!['symptomEntries']}',
                  icon: Icons.healing,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Flare Events',
                  value: '${_overview!['flareCount']}',
                  icon: Icons.warning,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Avg Pain',
                  value: (_overview!['averagePain'] as double).toStringAsFixed(1),
                  icon: Icons.favorite,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Med Adherence',
                  value:
                      '${(_overview!['medicationAdherence'] as double).toStringAsFixed(0)}%',
                  icon: Icons.medication,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_overview!['latestSibdqScore'] != null) ...[
            Text(
              'Latest SIBDQ Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getScoreColor(_overview!['latestSibdqScore']),
                      ),
                      child: Center(
                        child: Text(
                          '${_overview!['latestSibdqScore']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quality of Life Score',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Out of 70 points',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymptomsTab() {
    return FutureBuilder<List<SymptomEntry>>(
      future: _clinicianService.getPatientSymptoms(
        widget.patient.id,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No symptom data available'));
        }

        final symptoms = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: symptoms.length,
          itemBuilder: (context, index) {
            final symptom = symptoms[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: symptom.isFlare
                        ? AppTheme.errorColor.withValues(alpha: 0.1)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${symptom.severityScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: symptom.isFlare
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Pain: ${symptom.painLevel}, Fatigue: ${symptom.fatigueLevel}',
                ),
                subtitle: Text(
                  '${symptom.timestamp.day}/${symptom.timestamp.month}/${symptom.timestamp.year}',
                ),
                trailing: symptom.isFlare
                    ? const Chip(
                        label: Text('Flare'),
                        backgroundColor: AppTheme.errorColor,
                        labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodTab() {
    return FutureBuilder<List<MoodEntry>>(
      future: _clinicianService.getPatientMoodEntries(
        widget.patient.id,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No mood data available'));
        }

        final entries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  _getMoodEmoji(entry.moodLevel),
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text('Mood: ${entry.moodLevel.name}'),
                subtitle: Text(
                  'Stress: ${entry.stressLevel.name}, Sleep: ${entry.sleepQuality.name}',
                ),
                trailing: Text(
                  '${entry.timestamp.day}/${entry.timestamp.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDietTab() {
    return FutureBuilder<List<DietEntry>>(
      future: _clinicianService.getPatientDietEntries(
        widget.patient.id,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No diet data available'));
        }

        final entries = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.restaurant,
                  color: entry.triggeredSymptoms
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
                title: Text(entry.mealType.name),
                subtitle: Text(
                  entry.foods.map((f) => f.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: entry.triggeredSymptoms
                    ? const Icon(Icons.warning, color: AppTheme.errorColor)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSIBDQTab() {
    return FutureBuilder<List<SIBDQResponse>>(
      future: _clinicianService.getPatientSIBDQResponses(widget.patient.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No SIBDQ data available'));
        }

        final responses = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: responses.length,
          itemBuilder: (context, index) {
            final response = responses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getScoreColor(response.totalScore),
                  ),
                  child: Center(
                    child: Text(
                      '${response.totalScore}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  '${response.timestamp.day}/${response.timestamp.month}/${response.timestamp.year}',
                ),
                subtitle: Text(
                  'Bowel: ${response.bowelSymptomsDomain}, Emotional: ${response.emotionalFunctionDomain}',
                ),
              ),
            );
          },
        );
      },
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

  Color _getScoreColor(int score) {
    if (score >= 60) return AppTheme.successColor;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting patient data...')),
    );

    try {
      final data = await _clinicianService.exportPatientData(
        widget.patient.id,
        _startDate,
        _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Population-level insights',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming Soon',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Advanced analytics features including flare prediction patterns, medication adherence trends, and population health insights will be available in a future update.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                authProvider.user?.displayName.substring(0, 1).toUpperCase() ??
                    'C',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.user?.displayName ?? 'Clinician',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              authProvider.user?.role.name ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => authProvider.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
