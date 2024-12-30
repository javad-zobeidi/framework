import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:vania/vania.dart';
import 'session_file_store .dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  HttpRequest? _request;

  final Duration _sessionLifeTime = Duration(seconds: env<int>('SESSION_LIFETIME', 3600));

  final Random _random = Random.secure();

  /// Generates a new session ID.
  ///
  /// This method creates a 64-byte random key using a secure random number generator,
  /// and encodes it using base64 URL encoding to ensure a unique and safe session ID.
  ///
  /// Returns:
  /// A base64 URL encoded string representing the session ID.
  String _generateSessionId() {
    final keyBytes = List<int>.generate(64, (_) => _random.nextInt(256));
    return base64Url.encode(keyBytes);
  }

  /// Starts a new session or retrieves an existing session ID from the request.
  ///
  /// This method initializes a session for the given HTTP request and response.
  /// If a 'SESSION_ID' cookie is already present in the request, its value is
  /// used as the session ID. Otherwise, a new session ID is generated and set
  /// as a cookie in the response.
  ///
  /// The session ID is stored in a cookie with properties configured for HTTP
  /// only access, insecure transmission (consider changing to true for secure
  /// transmission), a path set to '/', and an expiration set to the session
  /// timeout duration.
  ///
  /// Parameters:
  /// - [request]: The incoming HTTP request containing cookies.
  /// - [response]: The HTTP response where the session cookie will be added.
  ///
  /// Returns:
  /// A string representing the session ID.
  String sessionStart(HttpRequest request, HttpResponse response) {
    _request = null;

    _request ??= request;

    final cookie = request.cookies.firstWhere(
      (c) => c.name == 'SESSION_ID',
      orElse: () => Cookie('SESSION_ID', _generateSessionId()),
    );
    String sessionId = cookie.value;
    response.cookies.add(
      Cookie('SESSION_ID', sessionId)
        ..httpOnly = true
        ..secure = false
        ..path = '/'
        ..expires = DateTime.now().add(_sessionLifeTime),
    );

    return sessionId;
  }

  String? getSessionId() {
    final cookie = _request?.cookies.firstWhere(
      (c) => c.name == 'SESSION_ID',
      orElse: () => Cookie('SESSION_ID', ''),
    );
    return cookie?.value;
  }

  /// Retrieves all session data associated with the current session ID.
  ///
  /// This function checks if there is an active session by retrieving the
  /// session ID. If a session ID is found, it verifies the existence and
  /// validity of the session. If the session exists, it retrieves and returns
  /// the session data as a map. If the session does not exist or is invalid,
  /// it returns null.
  ///
  /// Returns:
  /// A map containing the session data if a valid session exists, otherwise
  /// returns null.
  Map<String, dynamic>? allSessions() {
    final sessionId = getSessionId();
    if (sessionId != null) {
      if (!SessionFileStore().hasSession(sessionId)) {
        return null;
      }
      Map<String, dynamic> session = {};

      session = SessionFileStore().retrieveSession(sessionId) ?? {};
      return session;
    }
    return null;
  }

  dynamic getSession(String key) {
    Map<String, dynamic>? session = allSessions();
    return session?[key];
  }

  /// Stores a value in the session data associated with the current session ID.
  ///
  /// If a session ID is found, it verifies the existence and validity of the session.
  /// If the session exists, it updates the session data by adding the given key-value pair,
  /// and saves the updated session data. If the session does not exist or is invalid,
  /// it does not store the value.
  ///
  Future<void> setSession(String key, dynamic value) async {
    final sessionId = getSessionId();
    if (sessionId != null) {
      Map<String, dynamic> session =
          SessionFileStore().retrieveSession(sessionId) ?? {};
      session.addAll({key: value});
      await SessionFileStore().storeSession(sessionId, session);
    }
  }

  /// Deletes a specific key from the current session data.
  ///
  /// If a session ID is found, it verifies the existence and validity of the session.
  /// If the session exists, it removes the given key from the session data, and saves the
  /// updated session data. If the session does not exist or is invalid, it does not delete
  /// the key.
  ///
  /// Parameters:
  /// - [key]: The key to be deleted from the session data.
  void deleteSessionKey(String key) {
    final sessionId = getSessionId();
    if (sessionId != null) {
      Map<String, dynamic> session =
          SessionFileStore().retrieveSession(sessionId) ?? {};
      session.remove(key);
      SessionFileStore().storeSession(sessionId, session);
    }
  }

  void destroySession() {
    final sessionId = getSessionId();
    if (sessionId != null) {
      SessionFileStore().deleteSession(sessionId);
    }
  }
}
