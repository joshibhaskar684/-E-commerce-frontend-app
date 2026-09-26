/// Form rules — identical to the website signup form (components/signup/page.jsx).
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _mobile = RegExp(r'^[0-9]{10}$');
  static final _pincode = RegExp(r'^[1-9][0-9]{5}$');

  static String? name(String? v) =>
      (v == null || v.trim().length < 3) ? 'Name must be at least 3 characters long.' : null;

  static String? mobile(String? v) =>
      (v == null || !_mobile.hasMatch(v.trim())) ? 'Please enter a valid 10-digit mobile number.' : null;

  static String? email(String? v) =>
      (v == null || !_email.hasMatch(v.trim())) ? 'Please enter a valid email address.' : null;

  static String? password(String? v) =>
      (v == null || v.length < 6) ? 'Password must be at least 6 characters long.' : null;

  static String? required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? '$field is required.' : null;

  static String? pincode(String? v) =>
      (v == null || !_pincode.hasMatch(v.trim())) ? 'Enter a valid 6-digit pincode.' : null;
}
