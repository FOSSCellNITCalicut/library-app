import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Change this to the actual backend URL when deploying.
const String _backendBaseUrl = 'http://10.0.2.2:8000'; // localhost for Android emulator

const String _refreshTokenKey = 'refresh_token';

const _secureStorage = FlutterSecureStorage();


class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _rollNo;
  String? _name;

  String? get accessToken => _accessToken;
  String? get rollNo => _rollNo;
  String? get name => _name;
  bool get isLoggedIn => _accessToken != null;

  /// POST /api/v1/login
  ///
  /// On success: stores the access token in memory and the refresh token in
  /// secure storage (OS Keychain/Keystore), then notifies listeners.
  ///
  /// [rememberMe] tells the backend to encrypt and store the password so it
  /// can silently re-authenticate with Koha if the CGISESSID session expires
  /// mid-action, instead of forcing the user to log in again. This is
  /// separate from the refresh token, which only keeps the app session
  /// alive -- it doesn't help once Koha's own session has gone stale.
  ///
  /// Throws a [String] error message on failure (wrong credentials, network
  /// error, etc.) so the UI can display it.
  Future<void> login(String rollNo, String password, {bool rememberMe = false}) async {
    final response = await http.post(
      Uri.parse('$_backendBaseUrl/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roll_no': rollNo, 'password': password, 'remember_me': rememberMe}),
    );

    if (response.statusCode == 401) {
      throw 'Invalid roll number or password.';
    }

    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode}). Please try again.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    _accessToken = data['access_token'] as String;
    _rollNo = (data['user'] as Map<String, dynamic>)['roll_no'] as String;
    _name = (data['user'] as Map<String, dynamic>)['name'] as String;

    // Refresh token goes into secure storage -- it lives across app restarts.
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: data['refresh_token'] as String,
    );

    notifyListeners();
  }

  /// POST /api/v1/auth/logout
  ///
  /// Clears in-memory state and deletes the stored refresh token.
  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('$_backendBaseUrl/api/v1/auth/logout'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
      } catch (_) {
        // Best-effort. Clear local state regardless.
      }
    }
    _accessToken = null;
    _rollNo = null;
    _name = null;
    await _secureStorage.delete(key: _refreshTokenKey);
    notifyListeners();
  }

  /// POST /api/v1/auth/refresh
  ///
  /// Called on app startup (if a stored refresh token exists) or when the
  /// backend returns 401 on a protected request.
  ///
  /// Returns true if the refresh succeeded, false if the session has expired
  /// and the user must log in again.
  Future<bool> tryRefresh() async {
    final stored = await _secureStorage.read(key: _refreshTokenKey);
    if (stored == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': stored}),
      );

      if (response.statusCode != 200) {
        await _secureStorage.delete(key: _refreshTokenKey);
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String;

      await _secureStorage.write(
        key: _refreshTokenKey,
        value: data['refresh_token'] as String,
      );

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
