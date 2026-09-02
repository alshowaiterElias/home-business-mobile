import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/data_controller.dart';

class StoreFilterSheet extends StatefulWidget {
  final String? initialGovernorateId;
  final Function(String? governorateId) onApply;

  const StoreFilterSheet({
    super.key,
    this.initialGovernorateId,
    required this.onApply,
  });

  @override
  State<StoreFilterSheet> createState() => _StoreFilterSheetState();
}

class _StoreFilterSheetState extends State<StoreFilterSheet> {
  String? _selectedGovernorateId;

  @override
  void initState() {
    super.initState();
    _selectedGovernorateId = widget.initialGovernorateId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataController = Get.find<DataController>();

    // Flatten governorates
    final List<dynamic> allGovernorates = [];
    for (var governorate in dataController.locations) {
      allGovernorates.add({
        'id': governorate['id'],
        'name': governorate['nameAr'],
      });
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.space24,
        right: AppTheme.space24,
        top: AppTheme.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space24,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          Text('تصفية المتاجر', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space24),

          // Governorate
          Text('المحافظة', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppTheme.space8),
          DropdownButtonFormField<String>(
            initialValue: _selectedGovernorateId,
            hint: const Text('جميع المحافظات'),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('جميع المحافظات')),
              ...allGovernorates.map((g) => DropdownMenuItem(
                value: g['id'].toString(),
                child: Text(g['name'] ?? ''),
              )),
            ],
            onChanged: (val) {
              setState(() => _selectedGovernorateId = val);
            },
          ),
          const SizedBox(height: AppTheme.space32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGovernorateId = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('إعادة تعيين'),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedGovernorateId);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
