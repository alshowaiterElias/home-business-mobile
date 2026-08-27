import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/create_store_controller.dart';

class CreateStoreScreen extends StatelessWidget {
  const CreateStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = Get.put(CreateStoreController());

    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء متجرك الخاص')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلاً بك في عالم الأعمال المنزلية! املأ تفاصيل متجرك للبدء في عرض منتجاتك للمشترين.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Logo
              Center(
                child: GestureDetector(
                  onTap: () => controller.pickImage(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primarySurface,
                        backgroundImage: controller.logoFile.value != null
                            ? FileImage(controller.logoFile.value!)
                            : null,
                        child: controller.logoFile.value == null
                            ? const Icon(
                                Icons.storefront_rounded,
                                size: 40,
                                color: AppTheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Center(
                child: Text(
                  'شعار المتجر (اختياري)',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              _FormField(
                label: 'اسم المتجر *',
                hint: 'مثال: مطبخ أم محمد',
                controller: controller.businessNameController,
              ),
              const SizedBox(height: AppTheme.space16),
              _FormField(
                label: 'الوصف',
                hint: 'نبذة قصيرة عن منتجاتك...',
                maxLines: 3,
                controller: controller.descriptionController,
              ),
              const SizedBox(height: AppTheme.space16),

              Text(
                'رقم التواصل (واتساب) *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.space8),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  hintText: '7XX XXX XXX',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      '+967',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              // Location dropdowns
              Text('المحافظة *', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: controller.selectedGovId.value.isEmpty
                        ? null
                        : controller.selectedGovId.value,
                    hint: Text(
                      'اختر المحافظة',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textHint,
                    ),
                    items: controller.locations.map<DropdownMenuItem<String>>((
                      gov,
                    ) {
                      return DropdownMenuItem<String>(
                        value: gov['id'],
                        child: Text(gov['nameAr']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectedGovId.value = val;
                        controller.selectedCityId.value = ''; // reset city
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              if (controller.selectedGovId.value.isNotEmpty) ...[
                Text(
                  'المدينة / المديرية *',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      menuMaxHeight: 250,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      value: controller.selectedCityId.value.isEmpty
                          ? null
                          : controller.selectedCityId.value,
                      hint: Text(
                        'اختر المدينة',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textHint,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textHint,
                      ),
                      items: () {
                        final gov = controller.locations.firstWhere(
                          (g) => g['id'] == controller.selectedGovId.value,
                          orElse: () => null,
                        );
                        if (gov == null) return <DropdownMenuItem<String>>[];
                        final cities = gov['cities'] as List<dynamic>? ?? [];
                        return cities.map<DropdownMenuItem<String>>((city) {
                          return DropdownMenuItem<String>(
                            value: city['id'],
                            child: Text(city['nameAr']),
                          );
                        }).toList();
                      }(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedCityId.value = val;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
              ],

              _FormField(
                label: 'تفاصيل العنوان',
                hint: 'اسم الشارع، حي، معلم بارز...',
                maxLines: 2,
                controller: controller.addressController,
              ),
              const SizedBox(height: AppTheme.space32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => controller.createStore(),
                  child: const Text('تأكيد وإنشاء المتجر'),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],
          ),
        );
      }),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  final TextEditingController? controller;
  const _FormField({
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
