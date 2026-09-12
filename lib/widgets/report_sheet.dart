import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../core/network/error_handler.dart';

/// Bottom sheet for reporting products, reviews, businesses, or messages.
/// Fetches admin-configured reasons dynamically from backend with safe offline fallbacks.
void showReportSheet(
  BuildContext context, {
  required String targetType, // PRODUCT, REVIEW, BUSINESS, MESSAGE
  required String targetId,
  required String targetName,
}) {
  final defaultReasons = targetType == 'PRODUCT'
      ? ['محتوى مخالف', 'صور غير لائقة', 'سعر مبالغ فيه', 'منتج وهمي', 'أخرى']
      : targetType == 'REVIEW'
      ? ['تعليق مسيء', 'تقييم غير عادل', 'محتوى مخالف', 'أخرى']
      : targetType == 'MESSAGE'
      ? ['رسالة احتيالية', 'محتوى مسيء', 'إزعاج/سبام', 'أخرى']
      : ['متجر احتيالي', 'معلومات خاطئة', 'سلوك غير لائق', 'أخرى'];

  String? selectedReason;
  List<String> reasons = List<String>.from(defaultReasons);
  bool isLoadingReasons = true;
  bool isSubmitting = false;
  final customController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);

        // Fetch dynamic reasons from backend once when sheet opens
        if (isLoadingReasons) {
          DataService.getReportReasons(targetType).then((fetched) {
            if (context.mounted && fetched.isNotEmpty) {
              setState(() {
                reasons = fetched;
                isLoadingReasons = false;
              });
            } else if (context.mounted) {
              setState(() {
                isLoadingReasons = false;
              });
            }
          }).catchError((_) {
            if (context.mounted) {
              setState(() {
                isLoadingReasons = false;
              });
            }
          });
        }

        final isOtherSelected = selectedReason == 'أخرى';
        final canSubmit = selectedReason != null &&
            !isSubmitting &&
            (!isOtherSelected || customController.text.trim().isNotEmpty);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                  const SizedBox(height: AppTheme.space20),

                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          color: context.colors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إبلاغ', style: theme.textTheme.headlineSmall),
                            Text(
                              targetName,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('اختر سبب الإبلاغ:', style: theme.textTheme.titleMedium),
                      if (isLoadingReasons)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),

                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (v) {
                      setState(() {
                        selectedReason = v;
                      });
                    },
                    child: Column(
                      children: reasons.map(
                        (r) => RadioListTile<String>(
                          value: r,
                          title: Text(r, style: theme.textTheme.bodyLarge),
                          activeColor: context.colors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ).toList(),
                    ),
                  ),

                  // Optional details if 'أخرى' is selected
                  if (isOtherSelected) ...[
                    const SizedBox(height: AppTheme.space8),
                    TextField(
                      controller: customController,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'يرجى توضيح سبب الإبلاغ...',
                        hintStyle: TextStyle(
                          color: context.colors.textHint,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: context.colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(color: context.colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(color: context.colors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(AppTheme.space12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: AppTheme.space16),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: canSubmit
                          ? () async {
                              setState(() => isSubmitting = true);
                              final finalReason = isOtherSelected &&
                                      customController.text.trim().isNotEmpty
                                  ? 'أخرى: ${customController.text.trim()}'
                                  : selectedReason!;

                              final primaryColor = context.colors.primary;
                              final errorColor = context.colors.error;

                              try {
                                await DataService.addReport(
                                  targetType,
                                  targetId,
                                  finalReason,
                                );
                                Get.back();
                                Get.snackbar(
                                  'تم الإبلاغ',
                                  'شكراً لمساعدتنا في الحفاظ على جودة المنصة',
                                  backgroundColor: primaryColor,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                Get.back();
                                Get.snackbar(
                                  'خطأ',
                                  ApiErrorHandler.handle(e),
                                  backgroundColor: errorColor,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.error,
                        disabledBackgroundColor: context.colors.divider,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'إرسال البلاغ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + AppTheme.space8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
