import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;

import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/error_handler.dart';
import '../../core/utils/image_compressor.dart';
import '../../controllers/seller_dashboard_controller.dart';
import '../../controllers/data_controller.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  bool isLoading = false;

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;

  late String selectedUnit;
  late String selectedCurrency;
  late String selectedCategoryId;
  late String selectedSubCategoryId;

  List<dynamic> existingImages = [];
  List<File> newImages = [];

  final dataController = Get.find<DataController>();
  final currencies = ['YER', 'SAR', 'USD'];

  List<String> get units {
    return dataController.unitsOfSale.isNotEmpty
        ? dataController.unitsOfSale
        : ['حبة', 'قطعة', 'كيلو', 'لتر'];
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    titleController = TextEditingController(text: p['title'] ?? '');
    descriptionController = TextEditingController(text: p['description'] ?? '');
    priceController = TextEditingController(text: '${p['price'] ?? ''}');

    selectedUnit =
        p['unitOfSale'] ??
        p['unit'] ??
        (units.isNotEmpty ? units.first : 'حبة');
    selectedCurrency = p['currency'] ?? 'YER';

    final rawCatId = p['categoryId'] ?? p['category']?['id'] ?? '';
    selectedCategoryId = '';
    selectedSubCategoryId = '';

    if (rawCatId.toString().isNotEmpty) {
      // 1. Check if rawCatId matches a main category ID
      for (var mainCat in dataController.categories) {
        if (mainCat['id'] == rawCatId) {
          selectedCategoryId = mainCat['id'];
          break;
        }
      }
      // 2. If not a main category, check if rawCatId matches a subcategory ID
      if (selectedCategoryId.isEmpty) {
        for (var mainCat in dataController.categories) {
          final children = mainCat['children'] as List<dynamic>? ?? [];
          for (var child in children) {
            if (child['id'] == rawCatId) {
              selectedCategoryId = mainCat['id'];
              selectedSubCategoryId = child['id'];
              break;
            }
          }
          if (selectedCategoryId.isNotEmpty) break;
        }
      }
    }

    existingImages = List.from(p['images'] ?? []);
  }

  Future<void> _pickNewImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      if (existingImages.length + newImages.length + picked.length > 5) {
        Get.snackbar(
          'تنبيه',
          'يمكنك اختيار 5 صور كحد أقصى للمنتج',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      setState(() {
        newImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  Future<void> _submitUpdate() async {
    if (titleController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedCategoryId.isEmpty ||
        (existingImages.isEmpty && newImages.isEmpty)) {
      Get.snackbar(
        'خطأ',
        'يرجى تعبئة الحقول المطلوبة وإبقاء صورة واحدة على الأقل',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final categoryId = selectedSubCategoryId.isNotEmpty
          ? selectedSubCategoryId
          : selectedCategoryId;

      final formData = dio.FormData.fromMap({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': priceController.text.trim(),
        'categoryId': categoryId,
        'unitOfSale': selectedUnit,
        'currency': selectedCurrency,
      });

      if (newImages.isNotEmpty) {
        final compressedImages = await ImageCompressor.compressFileList(
          newImages,
        );
        for (var file in compressedImages) {
          formData.files.add(
            MapEntry(
              'productImages',
              await dio.MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        }
      }

      final productId = widget.product['id'];
      final response = await ApiClient.instance.put(
        '/products/$productId',
        data: formData,
      );

      if (response.data['success'] == true) {
        if (Get.isRegistered<SellerDashboardController>()) {
          Get.find<SellerDashboardController>().fetchDashboardData();
        }
        Get.back(result: true); // close edit screen
        Get.snackbar(
          'تم التحديث',
          'تمت إعادة تقديم المنتج بنجاح وهو الآن قيد مراجعة الإدارة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar(
        'خطأ في التعديل',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل وإعادة تقديم المنتج')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revision note alert if present
                  if (widget.product['status'] == 'NEEDS_REVISION' &&
                      widget.product['revisionReason'] != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppTheme.space16),
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: Colors.amber.shade900,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ملاحظات الإدارة للتعديل:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.product['revisionReason']}',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text('صور المنتج', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppTheme.space8),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...existingImages.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final img = entry.value;
                          final imgUrl = img['imageUrl'] ?? '';
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: ApiClient.getImageUrl(imgUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(idx),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        ...newImages.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final file = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(idx),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (existingImages.length + newImages.length < 5)
                          GestureDetector(
                            onTap: _pickNewImages,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppTheme.textHint,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  _FormField(
                    label: 'اسم المنتج *',
                    hint: 'اسم المنتج',
                    controller: titleController,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _FormField(
                    label: 'الوصف',
                    hint: 'تفاصيل المنتج...',
                    maxLines: 4,
                    controller: descriptionController,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          label: 'السعر *',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          controller: priceController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وحدة البيع',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: units.contains(selectedUnit)
                                      ? selectedUnit
                                      : units.first,
                                  items: units
                                      .map(
                                        (u) => DropdownMenuItem<String>(
                                          value: u,
                                          child: Text(u),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedUnit = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),

                  Text('القسم الرئيسي *', style: theme.textTheme.titleMedium),
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
                    child: Builder(builder: (context) {
                      final isCategoryValid = dataController.categories.any(
                        (c) => c['id'] == selectedCategoryId,
                      );
                      final catValue = isCategoryValid ? selectedCategoryId : null;

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: catValue,
                          hint: const Text('اختر القسم'),
                          items: dataController.categories
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c['id'],
                                  child: Text(c['nameAr']),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedCategoryId = val;
                                selectedSubCategoryId = '';
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppTheme.space16),

                  if (selectedCategoryId.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final parentCat = dataController.categories.firstWhere(
                          (c) => c['id'] == selectedCategoryId,
                          orElse: () => null,
                        );
                        if (parentCat == null ||
                            parentCat['children'] == null ||
                            (parentCat['children'] as List).isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final subChildren =
                            parentCat['children'] as List<dynamic>;
                        final isSubValid = subChildren.any(
                          (c) => c['id'] == selectedSubCategoryId,
                        );
                        final subValue = isSubValid ? selectedSubCategoryId : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'القسم الفرعي (اختياري)',
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
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: subValue,
                                  hint: const Text('بدون قسم فرعي'),
                                  items: subChildren
                                      .map(
                                        (c) => DropdownMenuItem<String>(
                                          value: c['id'],
                                          child: Text(c['nameAr']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedSubCategoryId = val ?? '';
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],
                        );
                      },
                    ),
                  ],

                  Text('العملة', style: theme.textTheme.titleMedium),
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
                        value: selectedCurrency,
                        items: currencies
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: const Text('حفظ وإعادة التقديم للمراجعة'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                ],
              ),
            ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  const _FormField({
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
