import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/diet_model.dart';
import '../../providers/providers.dart';
import '../../config/app_theme.dart';

class DietTrackingScreen extends StatefulWidget {
  const DietTrackingScreen({super.key});

  @override
  State<DietTrackingScreen> createState() => _DietTrackingScreenState();
}

class _DietTrackingScreenState extends State<DietTrackingScreen> {
  MealType _mealType = MealType.breakfast;
  final List<FoodItem> _foods = [];
  int _waterIntake = 0;
  bool _triggeredSymptoms = false;
  final _notesController = TextEditingController();
  final _foodNameController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _foodNameController.dispose();
    super.dispose();
  }

  void _addFood() {
    if (_foodNameController.text.isEmpty) return;

    final dietProvider = context.read<DietProvider>();
    final isKnownTrigger = dietProvider.isFoodKnownTrigger(_foodNameController.text);

    setState(() {
      _foods.add(FoodItem(
        name: _foodNameController.text,
        category: FoodCategory.other,
        isKnownTrigger: isKnownTrigger,
      ));
      _foodNameController.clear();
    });
  }

  Future<void> _saveEntry() async {
    final l10n = AppLocalizations.of(context)!;
    if (_foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseAddFood),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final dietProvider = context.read<DietProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) return;

    final entry = DietEntry(
      id: const Uuid().v4(),
      oderId: userId,
      timestamp: DateTime.now(),
      mealType: _mealType,
      foods: _foods,
      waterIntake: _waterIntake,
      triggeredSymptoms: _triggeredSymptoms,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await dietProvider.addEntry(entry);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mealLoggedSuccess),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logMeal),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.mealType,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<MealType>(
              segments: MealType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.name),
                );
              }).toList(),
              selected: {_mealType},
              onSelectionChanged: (v) => setState(() => _mealType = v.first),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.foods,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _foodNameController,
                    decoration: InputDecoration(
                      hintText: l10n.addFoodItem,
                      prefixIcon: const Icon(Icons.restaurant),
                    ),
                    onSubmitted: (_) => _addFood(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addFood,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_foods.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foods.map((food) {
                  return Chip(
                    label: Text(food.name),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _foods.remove(food));
                    },
                    backgroundColor: food.isKnownTrigger
                        ? AppTheme.errorColor.withValues(alpha: 0.1)
                        : null,
                    avatar: food.isKnownTrigger
                        ? const Icon(Icons.warning, color: AppTheme.errorColor, size: 18)
                        : null,
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.waterIntake,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _waterIntake > 0
                      ? () => setState(() => _waterIntake--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_waterIntake',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _waterIntake++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(l10n.triggeredSymptoms),
              subtitle: Text(l10n.didMealCauseSymptoms),
              value: _triggeredSymptoms,
              onChanged: (v) => setState(() => _triggeredSymptoms = v),
              activeColor: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                hintText: l10n.anyObservationsAboutMeal,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            _buildKnownTriggers(l10n),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                child: Text(l10n.saveMeal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnownTriggers(AppLocalizations l10n) {
    return Consumer<DietProvider>(
      builder: (context, provider, _) {
        if (provider.triggers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.knownTriggers,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.triggers.take(5).map((trigger) {
                return Chip(
                  avatar: const Icon(Icons.warning, color: AppTheme.errorColor, size: 18),
                  label: Text(trigger.foodName),
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
