import 'dart:async';
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
  Timer? _timer;
  int _resendSeconds = 60;
  bool _canResend = false;
  final _phoneController = TextEditingController(text: '+967');
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        if (mounted) {
          setState(() {
            _resendSeconds--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.surface,
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppTheme.shadowMd,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
              Text('السوق المنزلي', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppTheme.space8),
              Text(
                _isOtpSent
                    ? 'أدخل رمز التحقق المرسل إلى واتساب'
                    : 'سجّل بإستخدام رقم الهاتف',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space48),

              // ── Phone Input ────────────────────────────────────
              if (!_isOtpSent) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('رقم الهاتف', style: theme.textTheme.titleMedium),
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
                      child: const Text('🇾🇪', style: TextStyle(fontSize: 22)),
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
                              final phone = _phoneController.text.trim();
                              if (phone.length < 10) {
                                Get.snackbar('تنبيه', 'يرجى إدخال رقم هاتف صحيح',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                                return;
                              }
                              final success = await auth.requestOTP(phone);
                              if (success) {
                                setState(() => _isOtpSent = true);
                                _startResendTimer();
                              }
                            },
                      child: auth.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('إرسال رمز التحقق'),
                    );
                  }),
                ),
              ],

              // ── OTP Input ────────────────────────────────────
              if (_isOtpSent) ...[
                // Phone number display with edit
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 18,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        _phoneController.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.colors.primary,
                          letterSpacing: 1,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      GestureDetector(
                        onTap: () {
                          _timer?.cancel();
                          setState(() {
                            _isOtpSent = false;
                            _canResend = false;
                          });
                        },
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // 4-Digit OTP Fields
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('رمز التحقق', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: AppTheme.space12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 56,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                  color: context.colors.divider, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                  color: context.colors.primary, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              _otpFocusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Obx(() {
                    final auth = Get.find<AuthController>();
                    return ElevatedButton(
                      onPressed: auth.isLoading.value
                          ? null
                          : () async {
                              final otp = _getOtpCode();
                              if (otp.length < 4) {
                                Get.snackbar(
                                    'تنبيه', 'الرجاء إدخال الرمز كاملاً (4 أرقام)',
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                                return;
                              }
                              await auth.verifyOTP(otp);
                            },
                      child: auth.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تأكيد رمز التحقق'),
                    );
                  }),
                ),
                const SizedBox(height: AppTheme.space16),

                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('لم يصلك الرمز؟', style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: _canResend
                          ? () async {
                              final auth = Get.find<AuthController>();
                              final success = await auth.requestOTP(
                                _phoneController.text.trim(),
                              );
                              if (success) {
                                _startResendTimer();
                              }
                            }
                          : null,
                      child: Text(
                        _canResend
                            ? 'إعادة الإرسال'
                            : 'إعادة الإرسال خلال (${_resendSeconds.toString().padLeft(2, '0')}ث)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _canResend ? context.colors.primary : context.colors.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                child: Text(
                  'تصفح كضيف',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.colors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
