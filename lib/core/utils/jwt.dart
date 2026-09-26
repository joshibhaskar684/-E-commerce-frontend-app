import 'dart:convert';

/// Reads the (unverified) payload of a JWT issued by AuthService.
///
/// Claims set by backend JwtUtil.generateToken:
///   sub     → email
///   userId  → numeric user id
///   roles   → e.g. ["ROLE_USER"]
///   exp     → expiry (7 days after login)
///
/// The signature is verified by the backend (RS256), the app only reads the
/// claims to show the role and to log out when the token has expired.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

bool isJwtExpired(String token) {
  final exp = decodeJwtPayload(token)?['exp'];
  if (exp is! num) return false; // no expiry claim → let the backend decide
  final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
}
