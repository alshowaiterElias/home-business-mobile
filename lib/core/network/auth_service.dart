import 'api_client.dart';

class AuthService {
  /// Request OTP — sends OTP via WhatsApp (Evolution API)
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

  /// Verify OTP code entered by the user
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

  /* =========================================================================
     LEGACY: Firebase Token exchange (commented out — pivoted to Evolution API)
     =========================================================================
  /// Exchange Firebase ID token for our backend JWT
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
     ========================================================================= */

  /// Fetch the logged-in user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.instance.get('/users/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Request account deletion
  static Future<Map<String, dynamic>> deleteAccount({String? reason}) async {
    try {
      final response = await ApiClient.instance.post('/users/delete-account', data: {
        if (reason != null) 'reason': reason,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
