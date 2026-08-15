import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/network/auth_service.dart';
import '../core/network/storage_service.dart';
import '../core/network/error_handler.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var hasStore = false.obs;
  var isLoading = false.obs;
  
  var currentUser = {}.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    if (StorageService.hasToken()) {
      try {
        await fetchProfile();
      } catch (e) {
        // Only log out if it's explicitly an auth error, not a network failure.
        // We assume token is still valid if we just couldn't reach the server.
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          StorageService.removeToken();
          isLoggedIn.value = false;
          hasStore.value = false;
        } else {
          // Assume still logged in offline, profile data just won't be fresh
          isLoggedIn.value = true;
        }
      }
    }
  }

/* =========================================================
   OLD OTP FLOW (Disabled)
   =========================================================
  Future<bool> requestOTP(String phoneNumber) async {
    isLoading.value = true;
    try {
      final response = await AuthService.requestOTP(phoneNumber);
      isLoading.value = false;
      return response['success'] == true;
    } catch (e) {
      isLoading.value = false;
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    isLoading.value = true;
    try {
      final response = await AuthService.verifyOTP(phoneNumber, otpCode);
      if (response['success'] == true && response['token'] != null) {
        await StorageService.saveToken(response['token']);
        isLoggedIn.value = true;
        
        final user = response['user'];
        if (user != null) {
          currentUser.value = user;
          hasStore.value = user['business'] != null;
        } else {
          await fetchProfile();
        }
        
        isLoading.value = false;
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
  ========================================================= */

  var verificationId = ''.obs;

  // NEW FIREBASE AUTH FLOW
  Future<bool> requestOTP(String phoneNumber) async {
    print('[FirebaseAuth] Starting requestOTP for: $phoneNumber');
    isLoading.value = true;
    final completer = Completer<bool>();

    try {
      print('[FirebaseAuth] Calling verifyPhoneNumber...');
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('[FirebaseAuth] verificationCompleted triggered automatically!');
          // Auto-retrieval (Android only)
          final success = await _signInWithCredential(credential);
          if (success) {
            print('[FirebaseAuth] Auto-retrieval sign-in successful. Navigating to /main');
            Get.offAllNamed('/main'); // Navigate on auto-success
          } else {
            print('[FirebaseAuth] Auto-retrieval sign-in failed.');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('[FirebaseAuth] verificationFailed! Code: ${e.code}, Message: ${e.message}');
          isLoading.value = false;
          final friendlyMsg = _getArabicErrorMessage(e);
          Get.snackbar(
            'تعذر إرسال الرمز',
            friendlyMsg,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(12),
          );
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verId, int? resendToken) {
          print('[FirebaseAuth] codeSent! VerificationId: $verId');
          isLoading.value = false;
          verificationId.value = verId;
          Get.snackbar(
            'تم إرسال الرمز',
            'تم إرسال رمز التحقق عبر الرسائل النصية',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(12),
          );
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verId) {
          print('[FirebaseAuth] codeAutoRetrievalTimeout! VerificationId: $verId');
          verificationId.value = verId;
        },
      );
      
      print('[FirebaseAuth] verifyPhoneNumber call returned, waiting for callbacks...');
      // Wait for codeSent or verificationFailed
      final result = await completer.future;
      print('[FirebaseAuth] requestOTP returning result: $result');
      return result;
    } catch (e) {
      print('[FirebaseAuth] Exception caught in requestOTP: $e');
      isLoading.value = false;
      final errorMsg = e is FirebaseAuthException ? _getArabicErrorMessage(e) : ApiErrorHandler.handle(e);
      Get.snackbar('خطأ', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white);
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    isLoading.value = true;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpCode,
      );
      return await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      Get.snackbar('خطأ في التحقق', _getArabicErrorMessage(e), backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('خطأ', 'رمز التحقق غير صحيح أو انتهت صلاحيته', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  String _getArabicErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'تم حظر المحاولات مؤقتاً لكثرة الطلبات من هذا الجهاز. يرجى المحاولة لاحقاً بعد عدة دقائق.';
      case 'invalid-phone-number':
        return 'رقم الهاتف الذي أدخلته غير صحيح. يرجى التأكد من كتابة الرقم بالشكل الصحيح.';
      case 'quota-exceeded':
        return 'تم تجاوز الحد اليومي المسموح به لرسائل التحقق. يرجى المحاولة غداً.';
      case 'invalid-verification-code':
        return 'رمز التحقق المدخل غير صحيح. يرجى التأكد من الأرقام وإعادة المحاولة.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'انتهت صلاحية رمز التحقق. يرجى إعادة طلب رمز جديد.';
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'تعذر التحقق من هوية التطبيق. يرجى التأكد من تحديث التطبيق إلى أحدث إصدار.';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة. يرجى التأكد من اتصالك بالإنترنت ثم المحاولة مرة أخرى.';
      case 'billing-not-enabled':
        return 'خدمة إرسال الرسائل غير متوفرة حالياً. يرجى التواصل مع الدعم الفني.';
      case 'unknown':
        if (e.message != null && (e.message!.contains('39') || e.message!.contains('internal error'))) {
          return 'تعذر التثبت من هوية الجهاز بشكل آمن. يرجى إغلاق التطبيق وإعادة المحاولة.';
        }
        return e.message ?? 'حدث خطأ أثناء إجراء عملية التحقق. يرجى المحاولة مرة أخرى.';
      default:
        return e.message ?? 'حدث خطأ أثناء إجراء عملية التحقق. يرجى المحاولة مرة أخرى.';
    }
  }

  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          final response = await AuthService.verifyFirebaseToken(idToken);
          if (response['success'] == true && response['token'] != null) {
            await StorageService.saveToken(response['token']);
            isLoggedIn.value = true;
            
            final user = response['user'];
            if (user != null) {
              currentUser.value = user;
              hasStore.value = user['business'] != null;
            } else {
              await fetchProfile();
            }
            
            isLoading.value = false;
            return true;
          }
        }
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
    StorageService.removeToken();
    isLoggedIn.value = false;
    hasStore.value = false;
    currentUser.value = {};
    Get.offAllNamed('/main');
  }

  void createStore() {
    hasStore.value = true;
  }
}
