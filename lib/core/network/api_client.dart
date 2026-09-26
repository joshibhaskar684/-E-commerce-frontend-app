import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// The single HTTP client of the app — the Flutter version of the `axios`
/// calls in the website's redux actions.
///
/// Every request goes to `<baseUrl><path>`, e.g.
///   http://localhost:8085/products/page?pageno=0&pagesize=12
///
/// * Adds `Authorization: Bearer <token>` when the user is logged in
///   (the website reads the token from the `usertoken` cookie instead).
/// * Prints `→ GET …` / `← 200 …` lines in the `flutter run` console so you
///   can watch requests travel from the phone to the PC.
/// * Converts every failure into an [ApiException] with a readable message.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.defaultApiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.connectTimeout,
        contentType: Headers.jsonContentType,
        headers: {'Accept': 'application/json'},
        // Spring Security answers some auth failures with a 302 redirect
        // to its login page; treat that as an error instead of following it.
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.instance.cachedToken;
          final wantsAuth = options.extra[_authKey] != false;
          if (wantsAuth && token != null) {
            if (TokenStorage.instance.hasValidToken) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              // An expired JWT makes the backend filters throw (HTTP 500),
              // so drop it here and ask the user to log in again.
              onSessionExpired?.call();
            }
          }
          options.extra['startedAt'] = DateTime.now().millisecondsSinceEpoch;
          if (kDebugMode) {
            debugPrint('[API] → ${options.method} ${options.uri}'
                '${options.headers.containsKey('Authorization') ? '  (with Bearer token)' : ''}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log(response.requestOptions, response.statusCode);
          handler.next(response);
        },
        onError: (error, handler) {
          _log(error.requestOptions, error.response?.statusCode, error: error.type.name);
          final hadToken = error.requestOptions.headers.containsKey('Authorization');
          if (hadToken && error.response?.statusCode == 401) onSessionExpired?.call();
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  static const _authKey = 'auth';

  late final Dio _dio;

  /// Set by AuthProvider: called when the stored token is expired/rejected.
  VoidCallback? onSessionExpired;

  String get baseUrl => _dio.options.baseUrl;
  set baseUrl(String url) => _dio.options.baseUrl = url;

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() => _dio.get(path, queryParameters: query, options: _opts(auth)));

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query, bool auth = true}) =>
      _send(() => _dio.post(path, data: data ?? const {}, queryParameters: query, options: _opts(auth)));

  Future<dynamic> put(String path, {Object? data, bool auth = true}) =>
      _send(() => _dio.put(path, data: data, options: _opts(auth)));

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _send(() => _dio.delete(path, options: _opts(auth)));

  /// Reachability check used by the Server settings screen: calls a public
  /// endpoint on [url] (or the current base URL) without saving anything.
  Future<Duration> ping([String? url]) async {
    final probe = Dio(BaseOptions(
      baseUrl: url ?? baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final watch = Stopwatch()..start();
    try {
      await probe.get('/products/page', queryParameters: {'pageno': 0, 'pagesize': 1});
      return watch.elapsed;
    } on DioException catch (e) {
      throw _toApiException(e);
    } finally {
      probe.close();
    }
  }

  Options _opts(bool auth) => Options(extra: {_authKey: auth});

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.sendTimeout:
        return ApiException(
          'Cannot reach the server at ${e.requestOptions.baseUrl}.\n'
          'Make sure the backend is running and the phone can reach your PC '
          '(USB: run "adb reverse tcp:8085 tcp:8085", Wi-Fi: use the PC IP).',
          isNetworkError: true,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException('The server took too long to respond. Please try again.',
            isNetworkError: true);
      case DioExceptionType.badCertificate:
        return ApiException('Secure connection failed (bad certificate).', isNetworkError: true);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled.');
      default:
        break;
    }
    final status = e.response?.statusCode;
    return ApiException(
      _extractMessage(e.response?.data) ?? _defaultMessage(status),
      statusCode: status,
    );
  }

  /// Same idea as the website: err.response.data.message || data.error.
  String? _extractMessage(dynamic data) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'reply']) {
        final v = data[key];
        if (v is String && v.trim().isNotEmpty && !_isGeneric(v)) return v.trim();
      }
    } else if (data is String) {
      final s = data.trim();
      if (s.isNotEmpty && s.length < 200 && !s.startsWith('<')) return s;
    }
    return null;
  }

  // Spring's default /error body only has the reason phrase — not helpful.
  bool _isGeneric(String s) => const {
        'Internal Server Error',
        'Bad Request',
        'Not Found',
        'Forbidden',
        'Unauthorized',
      }.contains(s);

  String _defaultMessage(int? status) {
    switch (status) {
      case 400:
        return 'Invalid request. Please check the details and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'Please log in to continue.';
      case 404:
        return 'Not found on the server (404).';
      case 409:
        return 'This already exists.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 502:
      case 503:
        return 'Service is starting or unavailable ($status). Try again in a few seconds.';
      default:
        if (status != null && status >= 500) {
          return 'Server error ($status). Please try again.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  void _log(RequestOptions o, int? status, {String? error}) {
    if (!kDebugMode) return;
    final started = o.extra['startedAt'] as int?;
    final ms = started == null ? '' : ' ${DateTime.now().millisecondsSinceEpoch - started}ms';
    debugPrint('[API] ← ${status ?? error ?? '???'} ${o.method} ${o.uri}$ms');
  }
}
