import '../config/api_endpoints.dart';
import '../core/network/api_client.dart';

/// Mirrors website `src/redux-store/checkout/action.js`
/// (CreatePayment and VerifyPayment, Razorpay payment links).
class PaymentService {
  PaymentService({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// CreatePayment → POST /api/payments/{id}  (Bearer token, empty body)
  /// Returns the backend JSON; `payment_link_url` is opened in the browser.
  Future<Map<String, dynamic>> createPayment(String id) async {
    final data = await _api.post(ApiEndpoints.createPayment(id));
    return data is Map ? Map<String, dynamic>.from(data) : {'raw': data};
  }

  /// VerifyPayment → GET /api/payments?razorpay_payment_id&…&purchase_id
  /// Call this from the payment callback once Razorpay redirects back.
  Future<dynamic> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayPaymentLinkId,
    required String razorpayPaymentLinkStatus,
    required String purchaseId,
  }) {
    return _api.get(ApiEndpoints.verifyPayment, query: {
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_payment_link_id': razorpayPaymentLinkId,
      'razorpay_payment_link_status': razorpayPaymentLinkStatus,
      'purchase_id': purchaseId,
    });
  }
}
