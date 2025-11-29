import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class TranslationManagementScreen extends StatefulWidget {
  const TranslationManagementScreen({super.key});

  @override
  State<TranslationManagementScreen> createState() => _TranslationManagementScreenState();
}

class _TranslationManagementScreenState extends State<TranslationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLanguage = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.translationManagement,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddTranslationDialog(context, l10n),
                icon: const Icon(Icons.add),
                label: Text(l10n.addTranslation),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchTranslations,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedLanguage,
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.allLanguages)),
                  DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                  DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('translations')
                  .orderBy('key')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.translate,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTranslationsYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.addTranslationsToStart,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _initializeDefaultTranslations(context, l10n),
                          icon: const Icon(Icons.upload),
                          label: Text(l10n.loadDefaultTranslations),
                        ),
                      ],
                    ),
                  );
                }

                final translations = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final key = (data['key'] as String? ?? '').toLowerCase();
                  final en = (data['en'] as String? ?? '').toLowerCase();
                  final ar = (data['ar'] as String? ?? '').toLowerCase();

                  if (_searchQuery.isNotEmpty) {
                    if (!key.contains(_searchQuery) &&
                        !en.contains(_searchQuery) &&
                        !ar.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                return Card(
                  child: ListView.separated(
                    itemCount: translations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = translations[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          data['key'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('EN: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                Expanded(child: Text(data['en'] ?? '')),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('AR: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                Expanded(
                                  child: Text(
                                    data['ar'] ?? '',
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTranslationDialog(
                                context,
                                l10n,
                                doc.id,
                                data,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                              onPressed: () => _deleteTranslation(context, l10n, doc.id),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTranslationDialog(BuildContext context, AppLocalizations l10n) async {
    final keyController = TextEditingController();
    final enController = TextEditingController();
    final arController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTranslation),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: l10n.translationKey,
                  hintText: 'e.g., welcomeMessage',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: enController,
                decoration: InputDecoration(
                  labelText: l10n.englishText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: arController,
                decoration: InputDecoration(
                  labelText: l10n.arabicText,
                  border: const OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (keyController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('translations').add({
                  'key': keyController.text,
                  'en': enController.text,
                  'ar': arController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTranslationDialog(
    BuildContext context,
    AppLocalizations l10n,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final keyController = TextEditingController(text: data['key']);
    final enController = TextEditingController(text: data['en']);
    final arController = TextEditingController(text: data['ar']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTranslation),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: l10n.translationKey,
                  border: const OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: enController,
                decoration: InputDecoration(
                  labelText: l10n.englishText,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: arController,
                decoration: InputDecoration(
                  labelText: l10n.arabicText,
                  border: const OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('translations')
                  .doc(docId)
                  .update({
                'en': enController.text,
                'ar': arController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTranslation(
    BuildContext context,
    AppLocalizations l10n,
    String docId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTranslation),
        content: Text(l10n.deleteTranslationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('translations').doc(docId).delete();
    }
  }

  Future<void> _initializeDefaultTranslations(BuildContext context, AppLocalizations l10n) async {
    final defaultTranslations = {
      'appTitle': {'en': "Crohn's Experience", 'ar': 'تجربة كرون'},
      'dashboard': {'en': 'Dashboard', 'ar': 'الرئيسية'},
      'track': {'en': 'Track', 'ar': 'التتبع'},
      'journal': {'en': 'Journal', 'ar': 'اليوميات'},
      'profile': {'en': 'Profile', 'ar': 'الملف الشخصي'},
      'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
      'logSymptoms': {'en': 'Log Symptoms', 'ar': 'تسجيل الأعراض'},
      'medications': {'en': 'Medications', 'ar': 'الأدوية'},
      'logMeal': {'en': 'Log Meal', 'ar': 'تسجيل وجبة'},
      'moodCheckin': {'en': 'Mood Check-in', 'ar': 'تسجيل المزاج'},
    };

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('translations');

    for (final entry in defaultTranslations.entries) {
      final docRef = collection.doc();
      batch.set(docRef, {
        'key': entry.key,
        'en': entry.value['en'],
        'ar': entry.value['ar'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translationsLoaded),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
