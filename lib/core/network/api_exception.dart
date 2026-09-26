/// Error thrown by every service call, with a message that is safe to show
/// to the user (like the toast messages on the website).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  final String message;
  final int? statusCode;

  /// True when the phone could not reach the backend at all
  /// (wrong URL, backend not running, adb reverse missing, firewall …).
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
