import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/collection_service.dart';
import '../../widgets/app_cached_image.dart';
import 'edit_collection_items_screen.dart';

class CreateCollectionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCollection;

  const CreateCollectionScreen({super.key, this.initialCollection});

  bool get isEditing => initialCollection != null;

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  File? _coverImage;
  String? _existingCoverUrl;
  bool _isActive = true;
  bool _isSubmitting = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final col = widget.initialCollection;
    _titleController = TextEditingController(text: col?['title']?.toString() ?? '');
    _descController = TextEditingController(text: col?['description']?.toString() ?? '');
    _existingCoverUrl = col?['coverUrl']?.toString();
    _isActive = col?['isActive'] != false;
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _coverImage = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        final id = widget.initialCollection!['id'].toString();
        await CollectionService.updateCollection(
          id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          isActive: _isActive,
          coverFile: _coverImage,
        );

        Get.back(result: true);
        Get.snackbar(
          'نجاح',
          'تم تحديث بيانات المجموعة بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final collection = await CollectionService.createCollection(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          coverFile: _coverImage,
        );

        Get.snackbar(
          'نجاح',
          'تم إنشاء المجموعة بنجاح! يمكنك الآن اختيار المنتجات لإضافتها.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to add products to the new collection
        if (mounted) {
          Get.off(
            () => EditCollectionItemsScreen(
              collectionId: collection['id'],
              collectionTitle: _titleController.text.trim(),
            ),
          );
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ المجموعة: $e', backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المجموعة ✏️' : 'إنشاء مجموعة جديدة ✨',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover Image Selector ──
              Text(
                'صورة الغلاف (اختياري)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: _coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_coverImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        )
                      : (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppCachedImage(
                                    imageUrl: ApiClient.getImageUrl(_existingCoverUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AppTheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'اضغط لاختيار صورة غلاف للمجموعة',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إذا لم تختر صورة، سيتم عرض صور المنتجات كمعاينة',
                                  style: TextStyle(fontSize: 11, color: context.colors.textHint),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── Title Field ──
              Text(
                'عنوان المجموعة *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'مثال: تشكيلة حلويات العيد، بوكسات الهدايا',
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال عنوان للمجموعة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space20),

              // ── Description Field ──
              Text(
                'وصف المجموعة (اختياري)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب وصفاً جذاباً يشرح محتويات ومناسبة هذه المجموعة...',
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── Active Status Switch ──
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: SwitchListTile(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    title: const Text(
                      'إظهار المجموعة للجمهور',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'المجموعة ظاهرة الآن في صفحة المتجر'
                          : 'المجموعة مخفية حالياً ولن يراها العملاء',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isActive ? Colors.teal : Colors.grey,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
              ],

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'حفظ التعديلات' : 'متابعة وإضافة المنتجات ➡️',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: const Text('المعرض'),
                onTap: () {
                  Get.back();
                  _pickCoverImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: const Text('الكاميرا'),
                onTap: () {
                  Get.back();
                  _pickCoverImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
