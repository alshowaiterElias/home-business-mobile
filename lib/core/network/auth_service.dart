import 'api_client.dart';

class AuthService {
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

  /// Fetch the logged-in user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.instance.get('/users/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
