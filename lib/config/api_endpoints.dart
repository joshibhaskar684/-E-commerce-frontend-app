/// Every backend route the app calls.
///
/// These are the same routes the Next.js website calls from
/// `src/redux-store/**/action.js`. All of them go to the API Gateway
/// (port 8085), which forwards them to the right microservice:
///
///   /auth/**      → AUTH-SERVICE
///   /products/**  → PRODUCTS-SERVICE  (port 8081)
///   /cart/**      → CART-SERVICE      (port 8083)
///
/// (routes defined in backend/ApiGateway/.../CorsGlobalConfig.java)
class ApiEndpoints {
  ApiEndpoints._();

  // ── AuthService ────────────────────────────────────────────────────────
  /// POST {email, password} → {token, message}
  static const login = '/auth/login';

  /// POST {name, mobileno, email, password} → 201 {token:"", message}
  static const signup = '/auth/signup';

  /// GET (Bearer) → {name, mobileno, email, role}
  static const profile = '/auth/profile';

  // ── ProductService ─────────────────────────────────────────────────────
  /// GET ?pageno&pagesize → `Page<ProductsDto>` (Spring)
  static const productsPage = '/products/page';

  /// GET ?category&pageno&pagesize → `Page<ProductsDto>`
  static const productsByCategory = '/products/page/category/main';

  /// GET ?query&pageno&pagesize → `Page<ProductsDto>`
  static const productsByQuery = '/products/page/query/main';

  /// GET ?q → search suggestions (website SearchBar)
  static const suggestions = '/products/suggestions';

  /// GET → `List<CategoryNode>` ({id, name, children})
  static const categoryTree = '/products/category/tree';

  /// GET → full Product document
  static String productById(String id) => '/products/$id';

  // ── CartService (all need "Authorization: Bearer <token>") ─────────────
  /// GET → Cart{id, userId, items[], summary{}}
  static const cart = '/cart';

  /// POST {productId, quantity, productName, productImage, price} → Cart
  static const cartAddItem = '/cart/item/add';

  /// PUT {productId, quantity} → Cart
  static const cartItem = '/cart/item';

  /// DELETE → Cart
  static String cartRemoveItem(String productId) => '/cart/item/$productId';

  /// DELETE → Cart
  static const cartClear = '/cart/clear';

  /// GET → int
  static const cartCount = '/cart/count';

  // ── PaymentService (same paths as website redux-store/checkout/action.js)
  /// POST (Bearer) → {payment_link_url, ...}
  static String createPayment(String id) => '/api/payments/$id';

  /// GET (Bearer) ?razorpay_payment_id&razorpay_payment_link_id
  ///               &razorpay_payment_link_status&purchase_id
  static const verifyPayment = '/api/payments';
}
