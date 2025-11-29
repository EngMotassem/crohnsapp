import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _targetAudience = 'all';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendNotification,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: l10n.notificationTitle,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: l10n.notificationBody,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.targetAudience),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(l10n.allUsers)),
                        DropdownMenuItem(value: 'patient', child: Text(l10n.patientsOnly)),
                        DropdownMenuItem(value: 'clinician', child: Text(l10n.cliniciansOnly)),
                        DropdownMenuItem(value: 'researcher', child: Text(l10n.researchersOnly)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _targetAudience = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : () => _sendNotification(context, l10n),
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSending ? l10n.sending : l10n.sendNotification),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notificationHistory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .orderBy('sentAt', descending: true)
                            .limit(20)
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
                                    Icons.notifications_none,
                                    size: 64,
                                    color: AppTheme.textLight,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noNotificationsSent,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: snapshot.data!.docs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final sentAt = (data['sentAt'] as Timestamp?)?.toDate();

                                                            return ListTile(
                                                              leading: CircleAvatar(
                                                                backgroundColor: _getStatusColor(data['status']).withOpacity(0.1),
                                                                child: Icon(
                                                                  _getStatusIcon(data['status']),
                                                                  color: _getStatusColor(data['status']),
                                                                ),
                                                              ),
                                                              title: Text(
                                                                data['title'] ?? '',
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                              subtitle: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(data['body'] ?? ''),
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    children: [
                                                                      Icon(Icons.people, size: 14, color: AppTheme.textLight),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        _getAudienceLabel(data['targetAudience'] ?? 'all', l10n),
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: AppTheme.textLight,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 16),
                                                                      Icon(Icons.access_time, size: 14, color: AppTheme.textLight),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        sentAt != null ? _formatDate(sentAt) : '',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: AppTheme.textLight,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  if (data['sentCount'] != null || data['status'] != null)
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(top: 4),
                                                                      child: Row(
                                                                        children: [
                                                                          Icon(
                                                                            data['status'] == 'sent' ? Icons.check_circle : 
                                                                            data['status'] == 'error' ? Icons.error : Icons.pending,
                                                                            size: 14,
                                                                            color: _getStatusColor(data['status']),
                                                                          ),
                                                                          const SizedBox(width: 4),
                                                                          Text(
                                                                            data['status'] == 'sent' 
                                                                                ? 'Sent to ${data['sentCount'] ?? 0} devices'
                                                                                : data['status'] == 'error'
                                                                                    ? 'Error: ${data['error'] ?? 'Unknown'}'
                                                                                    : data['status'] == 'no_tokens'
                                                                                        ? 'No devices to send to'
                                                                                        : 'Pending...',
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: _getStatusColor(data['status']),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              isThreeLine: true,
                                                            );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAudienceLabel(String audience, AppLocalizations l10n) {
    switch (audience) {
      case 'patient':
        return l10n.patientsOnly;
      case 'clinician':
        return l10n.cliniciansOnly;
      case 'researcher':
        return l10n.researchersOnly;
      default:
        return l10n.allUsers;
    }
  }

    String _formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    Color _getStatusColor(String? status) {
      switch (status) {
        case 'sent':
          return AppTheme.successColor;
        case 'error':
          return AppTheme.errorColor;
        case 'no_tokens':
          return AppTheme.warningColor;
        default:
          return AppTheme.primaryColor;
      }
    }

    IconData _getStatusIcon(String? status) {
      switch (status) {
        case 'sent':
          return Icons.check_circle;
        case 'error':
          return Icons.error;
        case 'no_tokens':
          return Icons.warning;
        default:
          return Icons.notifications;
      }
    }

    Future<void> _sendNotification(BuildContext context, AppLocalizations l10n) async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseFillAllFields),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text,
        'body': _bodyController.text,
        'targetAudience': _targetAudience,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      _titleController.clear();
      _bodyController.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationSent),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
}
