import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../core/network/error_handler.dart';
/// Bottom sheet for reporting products, reviews, or businesses.
/// Matches the backend Report model: targetType, targetId, reason.
void showReportSheet(
  BuildContext context, {
  required String targetType, // PRODUCT, REVIEW, BUSINESS
  required String targetId,
  required String targetName,
}) {
  final reasons = targetType == 'PRODUCT'
      ? ['محتوى مخالف', 'صور غير لائقة', 'سعر مبالغ فيه', 'منتج وهمي', 'أخرى']
      : targetType == 'REVIEW'
      ? ['تعليق مسيء', 'تقييم غير عادل', 'محتوى مخالف', 'أخرى']
      : targetType == 'MESSAGE'
      ? ['رسالة احتيالية', 'محتوى مسيء', 'إزعاج/سبام', 'أخرى']
      : ['متجر احتيالي', 'معلومات خاطئة', 'سلوك غير لائق', 'أخرى'];

  String? selectedReason;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
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

                Text('اختر سبب الإبلاغ:', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.space12),

                ...reasons.map(
                  // ignore: deprecated_member_use
                  (r) => RadioListTile<String>(
                    value: r,
                    // ignore: deprecated_member_use
                    groupValue: selectedReason,
                    title: Text(r, style: theme.textTheme.bodyLarge),
                    activeColor: context.colors.primary,
                    contentPadding: EdgeInsets.zero,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => selectedReason = v),
                  ),
                ),

                const SizedBox(height: AppTheme.space16),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: selectedReason != null
                        ? () async {
                            try {
                              await DataService.addReport(targetType, targetId, selectedReason!);
                              Get.back();
                              Get.snackbar(
                                'تم الإبلاغ',
                                'شكراً لمساعدتنا في الحفاظ على جودة المنصة',
                                backgroundColor: context.colors.primary,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                              );
                            } catch (e) {
                              Get.back();
                              Get.snackbar(
                                'خطأ',
                                ApiErrorHandler.handle(e),
                                backgroundColor: context.colors.error,
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
                    child: const Text('إرسال البلاغ'),
                  ),
                ),
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + AppTheme.space8,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
