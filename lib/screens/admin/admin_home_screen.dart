import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'translation_management_screen.dart';
import 'user_management_screen.dart';
import 'statistics_screen.dart';
import 'notifications_screen.dart';
import 'data_export_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    TranslationManagementScreen(),
    UserManagementScreen(),
    StatisticsScreen(),
    NotificationsScreen(),
    DataExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(l10n.dashboard),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.translate_outlined),
                selectedIcon: const Icon(Icons.translate),
                label: Text(l10n.translations),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(l10n.users),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.analytics_outlined),
                selectedIcon: const Icon(Icons.analytics),
                label: Text(l10n.statistics),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: Text(l10n.notifications),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.download_outlined),
                selectedIcon: const Icon(Icons.download),
                label: Text(l10n.exportData),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }
}
