import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/auth_service.dart';
import '../core/network/storage_service.dart';
import '../core/network/error_handler.dart';
import '../core/network/push_notification_service.dart';

// =========================================================================
// LEGACY: Firebase Phone Auth imports (commented out — pivoted to Evolution API)
// =========================================================================
// import 'package:firebase_auth/firebase_auth.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var hasStore = false.obs;
  var isLoading = false.obs;

  var currentUser = {}.obs;

  // Current phone number being verified (used in OTP step)
  var currentPhone = ''.obs;

  // =========================================================================
  // LEGACY: Firebase Phone Auth state (commented out)
  // =========================================================================
  // var verificationId = ''.obs;
  // var resendToken = Rxn<int>();
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    if (StorageService.hasToken()) {
      try {
        await fetchProfile();
        PushNotificationService.syncFCMToken();
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          StorageService.removeToken();
          isLoggedIn.value = false;
          hasStore.value = false;
        } else {
          isLoggedIn.value = true;
          PushNotificationService.syncFCMToken();
        }
      }
    }
  }

  /// Requests OTP via backend → Evolution API (WhatsApp delivery)
  Future<bool> requestOTP(String phoneNumber) async {
    isLoading.value = true;

    try {
      final response = await AuthService.requestOTP(phoneNumber);

      if (response['success'] == true) {
        currentPhone.value = phoneNumber;
        isLoading.value = false;

        Get.snackbar(
          'تم إرسال رمز التحقق 📩',
          response['message'] ?? 'تحقق من رسائل الواتساب',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }

      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        response['message'] ?? 'فشل إرسال رمز التحقق',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar(
        'خطأ',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Verifies OTP code entered by the user against the backend
  Future<bool> verifyOTP(String otpCode) async {
    if (currentPhone.value.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى طلب رمز التحقق أولاً',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final response = await AuthService.verifyOTP(
        currentPhone.value,
        otpCode.trim(),
      );

      if (response['success'] == true && response['token'] != null) {
        await StorageService.saveToken(response['token']);
        isLoggedIn.value = true;
        PushNotificationService.syncFCMToken();

        final user = response['user'];
        if (user != null) {
          currentUser.value = user;
          hasStore.value = user['business'] != null;
        } else {
          await fetchProfile();
        }

        isLoading.value = false;

        Get.snackbar(
          'تم التحقق بنجاح! 🎉',
          'مرحباً بك في السوق المنزلي',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed('/main');
        return true;
      }

      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        response['message'] ?? 'فشل التحقق من الرمز',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar(
        'خطأ',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /* =========================================================================
     LEGACY: Firebase Phone Auth methods (commented out — pivoted to Evolution API)
     =========================================================================

  /// Sends OTP via Firebase Phone Auth
  Future<bool> requestOTP_firebase(String phoneNumber) async {
    isLoading.value = true;

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken.value,

        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) debugPrint('[Firebase Auth] Auto-verification triggered');
          await _signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          String errorMsg = 'فشل إرسال رمز التحقق';
          if (e.code == 'too-many-requests') {
            errorMsg = 'تم إرسال عدد كبير من الطلبات. يرجى المحاولة لاحقاً.';
          } else if (e.code == 'invalid-phone-number') {
            errorMsg = 'رقم الهاتف غير صحيح';
          }
          Get.snackbar('خطأ', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
        },

        codeSent: (String verId, int? forceResendToken) {
          isLoading.value = false;
          verificationId.value = verId;
          resendToken.value = forceResendToken;
        },

        codeAutoRetrievalTimeout: (String verId) {
          verificationId.value = verId;
        },
      );

      return true;
    } catch (e) {
      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  /// Verifies the 6-digit SMS code entered by the user (Firebase)
  Future<bool> verifyOTP_firebase(String smsCode) async {
    if (verificationId.value.isEmpty) {
      Get.snackbar('خطأ', 'يرجى طلب رمز التحقق أولاً', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    isLoading.value = true;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode.trim(),
      );
      return await _signInWithCredential(credential);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('خطأ', 'رمز التحقق غير صحيح', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  /// Signs in with Firebase credential, then exchanges the Firebase ID token for our backend JWT
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) throw Exception('Failed to get Firebase ID token');

      final response = await AuthService.verifyFirebaseToken(idToken);

      if (response['success'] == true && response['token'] != null) {
        await StorageService.saveToken(response['token']);
        isLoggedIn.value = true;
        PushNotificationService.syncFCMToken();

        final user = response['user'];
        if (user != null) {
          currentUser.value = user;
          hasStore.value = user['business'] != null;
        } else {
          await fetchProfile();
        }

        isLoading.value = false;
        Get.snackbar('تم التحقق بنجاح! 🎉', 'مرحباً بك في السوق المنزلي', backgroundColor: Colors.green, colorText: Colors.white);
        Get.offAllNamed('/main');
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

     ========================================================================= */

  Future<void> fetchProfile() async {
    try {
      final response = await AuthService.getProfile();
      if (response['success'] == true) {
        final user = response['data'];
        currentUser.value = user;
        isLoggedIn.value = true;
        hasStore.value = user['business'] != null;
      }
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    // LEGACY: _firebaseAuth.signOut();
    StorageService.removeToken();
    isLoggedIn.value = false;
    hasStore.value = false;
    currentUser.value = {};
    currentPhone.value = '';
    Get.offAllNamed('/main');
  }

  Future<bool> deleteAccount(String reason) async {
    isLoading.value = true;

    // Show non-dismissible loading overlay dialog
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.redAccent,
                  strokeWidth: 3,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'جاري حذف الحساب وتجميد البيانات...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final res = await AuthService.deleteAccount(reason: reason);

      // Close the loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (res['success'] == true) {
        // LEGACY: _firebaseAuth.signOut();
        StorageService.removeToken();
        isLoggedIn.value = false;
        hasStore.value = false;
        currentUser.value = {};
        isLoading.value = false;

        Get.offAllNamed('/main');
        Get.snackbar(
          'تم حذف الحساب بنجاح',
          'نتمنى لرؤيتك مجدداً في المستقبل',
          backgroundColor: Colors.deepOrange,
          colorText: Colors.white,
        );
        return true;
      }
      isLoading.value = false;
      return false;
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar(
        'خطأ',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  void createStore() {
    hasStore.value = true;
  }
}
