/// Matches backend `Signupdto` returned by `GET /auth/profile`
/// ({name, mobileno, email, role} — password is never sent back).
class UserProfile {
  const UserProfile({this.name, this.email, this.mobileno, this.role});

  final String? name;
  final String? email;
  final String? mobileno;
  final String? role;

  factory UserProfile.fromJson(dynamic json) {
    final j = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    return UserProfile(
      name: j['name'] as String?,
      email: j['email'] as String?,
      mobileno: j['mobileno'] as String?,
      role: j['role'] as String?,
    );
  }
}
