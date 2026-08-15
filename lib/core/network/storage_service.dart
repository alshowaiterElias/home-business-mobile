import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _recentSearchesKey = 'recent_searches';
  static late SharedPreferences _prefs;

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save token
  static Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  // Get token
  static String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  // Remove token (logout)
  static Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  // Check if user is logged in
  static bool hasToken() {
    return getToken() != null && getToken()!.isNotEmpty;
  }

  // Save recent search
  static Future<void> saveRecentSearch(String query) async {
    List<String> searches = getRecentSearches();
    if (searches.contains(query)) {
      searches.remove(query);
    }
    searches.insert(0, query);
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    await _prefs.setStringList(_recentSearchesKey, searches);
  }

  // Get recent searches
  static List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  // Clear recent searches
  static Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }
}
