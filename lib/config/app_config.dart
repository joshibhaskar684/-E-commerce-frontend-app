/// ─────────────────────────────────────────────────────────────────────────
///  APP CONFIGURATION  —  the first file to look at when something needs
///  to point somewhere else (backend URL, AI URL, page size …).
/// ─────────────────────────────────────────────────────────────────────────
///
/// How the backend (API Gateway) URL is chosen, highest priority first:
///
///   1. A URL saved in the app:  Account → Server settings
///      (stored on the phone, survives restarts, no rebuild needed).
///   2. A build-time value:
///        flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8085
///   3. [AppConfig.defaultApiBaseUrl] below  →  http://localhost:8085
///      which works on a real phone over USB after running:
///        adb reverse tcp:8085 tcp:8085
///
/// The website uses the same gateway through NEXT_PUBLIC_BACKEND_URL
/// (see website/.env), so both clients talk to exactly the same APIs.
class AppConfig {
  AppConfig._();

  static const String appName = 'Quick';

  /// Spring Cloud API Gateway (backend/ApiGateway, server.port=8085).
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8085',
  );

  /// Streaming AI assistant used by the website (components/ModalAi/AiModal.jsx).
  static const String aiChatUrl = String.fromEnvironment(
    'AI_CHAT_URL',
    defaultValue: 'https://ai.vhbuyio.in/api/chat',
  );

  /// Public website, used for policy pages.
  static const String websiteUrl = 'https://www.quicksin.in';
  static const String policyUrl = '$websiteUrl/policy';

  /// Network timeouts for every backend call.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 25);

  /// Products per page (the website uses pagesize=12).
  static const int pageSize = 12;
}
