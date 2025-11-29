import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isExporting = false;
  String? _exportingCollection;

  final List<Map<String, dynamic>> _collections = [
    {'name': 'users', 'icon': Icons.people, 'color': Colors.blue},
    {'name': 'symptom_logs', 'icon': Icons.healing, 'color': Colors.orange},
    {'name': 'medication_logs', 'icon': Icons.medication, 'color': Colors.green},
    {'name': 'diet_logs', 'icon': Icons.restaurant, 'color': Colors.purple},
    {'name': 'mood_logs', 'icon': Icons.mood, 'color': Colors.pink},
    {'name': 'video_diaries', 'icon': Icons.videocam, 'color': Colors.red},
    {'name': 'narratives', 'icon': Icons.edit_note, 'color': Colors.teal},
    {'name': 'translations', 'icon': Icons.translate, 'color': Colors.indigo},
    {'name': 'notifications', 'icon': Icons.notifications, 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dataExport,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.exportDataDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                final collection = _collections[index];
                final isExporting = _exportingCollection == collection['name'];

                return Card(
                  child: InkWell(
                    onTap: _isExporting
                        ? null
                        : () => _exportCollection(context, l10n, collection['name']),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            collection['icon'] as IconData,
                            size: 40,
                            color: collection['color'] as Color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getCollectionLabel(collection['name'], l10n),
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection(collection['name'])
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.docs.length ?? 0;
                              return Text(
                                '$count ${l10n.records}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textLight,
                                    ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (isExporting)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: _isExporting
                                      ? null
                                      : () => _exportCollection(
                                            context,
                                            l10n,
                                            collection['name'],
                                            format: 'json',
                                          ),
                                  icon: const Icon(Icons.code, size: 16),
                                  label: const Text('JSON'),
                                ),
                                TextButton.icon(
                                  onPressed: _isExporting
                                      ? null
                                      : () => _exportCollection(
                                            context,
                                            l10n,
                                            collection['name'],
                                            format: 'csv',
                                          ),
                                  icon: const Icon(Icons.table_chart, size: 16),
                                  label: const Text('CSV'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.download, size: 32, color: AppTheme.primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.exportAllData,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          l10n.exportAllDataDescription,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportAllData(context, l10n),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(l10n.exportAll),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCollectionLabel(String collection, AppLocalizations l10n) {
    switch (collection) {
      case 'users':
        return l10n.users;
      case 'symptom_logs':
        return l10n.symptomLogs;
      case 'medication_logs':
        return l10n.medicationLogs;
      case 'diet_logs':
        return l10n.dietLogs;
      case 'mood_logs':
        return l10n.moodLogs;
      case 'video_diaries':
        return l10n.videoDiaries;
      case 'narratives':
        return l10n.narratives;
      case 'translations':
        return l10n.translations;
      case 'notifications':
        return l10n.notifications;
      default:
        return collection;
    }
  }

  Future<void> _exportCollection(
    BuildContext context,
    AppLocalizations l10n,
    String collection, {
    String format = 'json',
  }) async {
    setState(() {
      _isExporting = true;
      _exportingCollection = collection;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection(collection).get();
      final data = snapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id;
        return _convertTimestamps(docData);
      }).toList();

      String content;
      String filename;
      String mimeType;

      if (format == 'csv') {
        content = _convertToCSV(data);
        filename = '${collection}_export.csv';
        mimeType = 'text/csv';
      } else {
        content = const JsonEncoder.withIndent('  ').convert(data);
        filename = '${collection}_export.json';
        mimeType = 'application/json';
      }

      _downloadFile(content, filename, mimeType);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportError}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
        _exportingCollection = null;
      });
    }
  }

  Future<void> _exportAllData(BuildContext context, AppLocalizations l10n) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final allData = <String, List<Map<String, dynamic>>>{};

      for (final collection in _collections) {
        final name = collection['name'] as String;
        final snapshot = await FirebaseFirestore.instance.collection(name).get();
        allData[name] = snapshot.docs.map((doc) {
          final docData = doc.data();
          docData['id'] = doc.id;
          return _convertTimestamps(docData);
        }).toList();
      }

      final content = const JsonEncoder.withIndent('  ').convert(allData);
      final filename = 'crohns_experience_full_export_${DateTime.now().millisecondsSinceEpoch}.json';

      _downloadFile(content, filename, 'application/json');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportError}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        result[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.value is Map) {
        result[entry.key] = _convertTimestamps(Map<String, dynamic>.from(entry.value as Map));
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  String _convertToCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final allKeys = <String>{};
    for (final item in data) {
      allKeys.addAll(item.keys);
    }
    final headers = allKeys.toList();

    final rows = <String>[headers.join(',')];
    for (final item in data) {
      final row = headers.map((key) {
        final value = item[key]?.toString() ?? '';
        if (value.contains(',') || value.contains('"') || value.contains('\n')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).join(',');
      rows.add(row);
    }

    return rows.join('\n');
  }

  void _downloadFile(String content, String filename, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
