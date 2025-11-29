import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        l10n.language,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageOption(
                          label: 'العربية',
                          isSelected: isArabic,
                          onTap: () => localeProvider.setLocale(const Locale('ar')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LanguageOption(
                          label: 'English',
                          isSelected: !isArabic,
                          onTap: () => localeProvider.setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
              title: Text(l10n.privacySettingsTitle),
              subtitle: Text(l10n.controlWhoCanSee),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              title: Text(l10n.about),
              subtitle: Text('${l10n.version} 1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: '1.0.0',
                  applicationLegalese: l10n.allRightsReserved,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.signOut),
                  content: Text(l10n.areYouSureSignOut),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l10n.signOut,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            label: Text(
              l10n.signOut,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
            if (isSelected)
              const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
