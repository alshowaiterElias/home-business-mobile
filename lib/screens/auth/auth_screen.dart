import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isOtpSent = false;
  final _phoneController = TextEditingController(text: '+967');
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Brand Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.shadowMd,
                ),
                child: const Icon(Icons.store_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppTheme.space24),
              Text('السوق المنزلي', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppTheme.space8),
              Text(
                _isOtpSent
                    ? 'أدخل رمز التحقق المرسل إلى هاتفك'
                    : 'سجّل بإستخدام رقم الهاتف',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space48),

              // ── Phone Input ────────────────────────────────────
              if (!_isOtpSent) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('رقم الهاتف',
                      style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: AppTheme.space8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text('🇾🇪',
                          style: const TextStyle(fontSize: 22)),
                    ),
                    hintText: '+967 7XX XXX XXX',
                  ),
                ),
                const SizedBox(height: AppTheme.space32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Obx(() {
                    final auth = Get.find<AuthController>();
                    return ElevatedButton(
                      onPressed: auth.isLoading.value
                          ? null
                          : () async {
                              final success = await auth.requestOTP(_phoneController.text);
                              if (success) {
                                setState(() => _isOtpSent = true);
                              }
                            },
                      child: auth.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('إرسال رمز التحقق'),
                    );
                  }),
                ),
              ],

              // ── OTP Input ──────────────────────────────────────
              if (_isOtpSent) ...[
                // Phone display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_android_rounded,
                          size: 18, color: AppTheme.primary),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        _phoneController.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      GestureDetector(
                        onTap: () => setState(() => _isOtpSent = false),
                        child: const Icon(Icons.edit_rounded,
                            size: 16, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space32),

                // OTP Fields
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) => Container(
                      width: 48,
                      height: 64,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: const BorderSide(color: AppTheme.divider, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _otpFocusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: AppTheme.space32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Obx(() {
                    final auth = Get.find<AuthController>();
                    return ElevatedButton(
                      onPressed: auth.isLoading.value
                          ? null
                          : () async {
                              // Collect OTP
                              final otp = _otpControllers.map((c) => c.text).join();
                              if (otp.length < 6) {
                                Get.snackbar('تنبيه', 'الرجاء إدخال الرمز كاملاً', 
                                    backgroundColor: AppTheme.error, colorText: Colors.white);
                                return;
                              }
                              
                              final success = await auth.verifyOTP(_phoneController.text, otp);
                              if (success) {
                                Get.offAllNamed('/main');
                              }
                            },
                      child: auth.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('تحقق'),
                    );
                  }),
                ),
                const SizedBox(height: AppTheme.space16),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لم يصلك الرمز؟',
                        style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () {},
                      child: Text('إعادة الإرسال',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                        )),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppTheme.space32),

              // Guest browsing
              TextButton(
                onPressed: () {
                  Get.offAllNamed('/main');
                },
                child: Text('تصفح كضيف',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    decoration: TextDecoration.underline,
                  )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
