import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../config/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'all';

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
          Text(
            l10n.userManagement,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchUsers,
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
                value: _selectedRole,
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.allRoles)),
                  DropdownMenuItem(value: 'patient', child: Text(l10n.patient)),
                  DropdownMenuItem(value: 'clinician', child: Text(l10n.clinicianRole)),
                  DropdownMenuItem(value: 'researcher', child: Text(l10n.researcher)),
                  DropdownMenuItem(value: 'admin', child: Text(l10n.admin)),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
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
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noUsersYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['displayName'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final role = data['role'] as String? ?? 'patient';

                  if (_searchQuery.isNotEmpty) {
                    if (!name.contains(_searchQuery) && !email.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  if (_selectedRole != 'all' && role != _selectedRole) {
                    return false;
                  }

                  return true;
                }).toList();

                return Card(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.name)),
                      DataColumn(label: Text(l10n.email)),
                      DataColumn(label: Text(l10n.role)),
                      DataColumn(label: Text(l10n.createdAt)),
                      DataColumn(label: Text(l10n.lastLogin)),
                      DataColumn(label: Text(l10n.actions)),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final createdAt = data['createdAt'] as Timestamp?;
                      final lastLogin = data['lastLoginAt'] as Timestamp?;

                      return DataRow(
                        cells: [
                          DataCell(Text(data['displayName'] ?? '')),
                          DataCell(Text(data['email'] ?? '')),
                          DataCell(_buildRoleChip(data['role'] ?? 'patient', l10n)),
                          DataCell(Text(
                            createdAt != null ? _formatDate(createdAt.toDate()) : '-',
                          )),
                          DataCell(Text(
                            lastLogin != null ? _formatDate(lastLogin.toDate()) : '-',
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditUserDialog(context, l10n, doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                onPressed: () => _deleteUser(context, l10n, doc.id),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, AppLocalizations l10n) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red;
        label = l10n.admin;
        break;
      case 'clinician':
        color = Colors.blue;
        label = l10n.clinicianRole;
        break;
      case 'researcher':
        color = Colors.green;
        label = l10n.researcher;
        break;
      default:
        color = AppTheme.primaryColor;
        label = l10n.patient;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    AppLocalizations l10n,
    String docId,
    Map<String, dynamic> data,
  ) async {
    String selectedRole = data['role'] ?? 'patient';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editUser),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.name}: ${data['displayName'] ?? ''}'),
                const SizedBox(height: 8),
                Text('${l10n.email}: ${data['email'] ?? ''}'),
                const SizedBox(height: 16),
                Text(l10n.role),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'patient', child: Text(l10n.patient)),
                    DropdownMenuItem(value: 'clinician', child: Text(l10n.clinicianRole)),
                    DropdownMenuItem(value: 'researcher', child: Text(l10n.researcher)),
                    DropdownMenuItem(value: 'admin', child: Text(l10n.admin)),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
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
                    .collection('users')
                    .doc(docId)
                    .update({'role': selectedRole});
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(
    BuildContext context,
    AppLocalizations l10n,
    String docId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(l10n.deleteUserConfirm),
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
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
    }
  }
}
