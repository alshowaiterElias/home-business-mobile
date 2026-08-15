import 'api_client.dart';

class AuthService {
  /* =========================================================
     OLD OTP FLOW (Disabled)
     =========================================================
  // Request OTP from backend
  static Future<Map<String, dynamic>> requestOTP(String phoneNumber) async {
    try {
      final response = await ApiClient.instance.post('/auth/request-otp', data: {
        'phoneNumber': phoneNumber,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP with backend
  static Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final response = await ApiClient.instance.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  ========================================================= */

  // NEW FIREBASE AUTH FLOW
  // Verify Firebase ID Token with backend
  static Future<Map<String, dynamic>> verifyFirebaseToken(String idToken) async {
    try {
      final response = await ApiClient.instance.post('/auth/verify-firebase-token', data: {
        'idToken': idToken,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch the logged-in user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.instance.get('/users/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
