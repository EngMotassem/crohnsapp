import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/medication_model.dart';
import '../../providers/providers.dart';
import '../../config/app_theme.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          if (provider.activeMedications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your medications to track adherence',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.activeMedications.length,
            itemBuilder: (context, index) {
              final medication = provider.activeMedications[index];
              final isLogged = provider.isMedicationLoggedToday(medication.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLogged
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLogged ? Icons.check : Icons.medication,
                      color: isLogged
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(medication.name),
                  subtitle: Text(
                    '${medication.dosage} ${medication.unit} - ${medication.frequency.name}',
                  ),
                  trailing: isLogged
                      ? const Chip(
                          label: Text('Taken'),
                          backgroundColor: AppTheme.successColor,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : ElevatedButton(
                          onPressed: () => _logMedication(context, medication),
                          child: const Text('Take'),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  void _logMedication(BuildContext context, Medication medication) async {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final log = MedicationLog(
      id: const Uuid().v4(),
      oderId: userId,
      medicationId: medication.id,
      timestamp: DateTime.now(),
      taken: true,
    );

    final success = await medicationProvider.logMedicationTaken(log);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication logged'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showAddMedicationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddMedicationSheet(),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  MedicationType _type = MedicationType.other;
  DoseFrequency _frequency = DoseFrequency.onceDaily;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final medication = Medication(
      id: const Uuid().v4(),
      userId: userId,
      name: _nameController.text,
      type: _type,
      dosage: _dosageController.text,
      unit: _unitController.text,
      frequency: _frequency,
      startDate: DateTime.now(),
    );

    final success = await medicationProvider.addMedication(medication);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication added'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Medication',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (mg, ml)',
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MedicationType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                ),
                items: MedicationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DoseFrequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                ),
                items: DoseFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMedication,
                child: const Text('Add Medication'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
