import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../core/network/api_exception.dart';

class ChatMessage {
  ChatMessage({required this.fromUser, required this.text});
  final bool fromUser;
  String text;
}

/// Streaming chat with the same AI endpoint as the website
/// (components/ModalAi/AiModal.jsx).
///
/// Request:  POST {messages:[{role:"user"|"assistant", content}]}
///           Accept: text/event-stream
/// Response: Server-Sent Events, e.g.
///           data: {"type":"delta","text":"Hello"}
///           data: {"type":"done"}
class AiChatService {
  AiChatService()
      : _dio = Dio(BaseOptions(
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: const Duration(minutes: 2),
        ));

  final Dio _dio;
  CancelToken? _cancelToken;

  /// Yields text chunks as they arrive.
  Stream<String> send(List<ChatMessage> history) async* {
    cancel();
    final cancelToken = _cancelToken = CancelToken();
    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        AppConfig.aiChatUrl,
        data: {
          'messages': history
              .where((m) => m.text.trim().isNotEmpty)
              .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
              .toList(),
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Content-Type': 'application/json', 'Accept': 'text/event-stream'},
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      throw ApiException('Unable to connect to Ayira AI. Please check your internet connection.',
          statusCode: e.response?.statusCode, isNetworkError: e.response == null);
    }

    final body = response.data;
    if (body == null) throw ApiException('The AI server did not return a response.');

    var buffer = '';
    try {
      await for (final chunk in body.stream.cast<List<int>>().transform(utf8.decoder)) {
        buffer += chunk.replaceAll('\r\n', '\n');
        final events = buffer.split('\n\n');
        buffer = events.removeLast(); // keep the incomplete tail
        for (final event in events) {
          final text = _parseEvent(event);
          if (text != null && text.isNotEmpty) yield text;
        }
      }
      final tail = _parseEvent(buffer);
      if (tail != null && tail.isNotEmpty) yield tail;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      rethrow;
    }
  }

  String? _parseEvent(String event) {
    final out = StringBuffer();
    for (final raw in event.split('\n')) {
      final line = raw.trim();
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      Map<String, dynamic>? parsed;
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) parsed = decoded;
      } catch (_) {
        continue; // incomplete / non-JSON line: ignore like the website does
      }
      if (parsed == null) continue;
      if (parsed['type'] == 'delta') out.write(parsed['text'] ?? '');
      if (parsed['type'] == 'error') {
        throw ApiException((parsed['message'] as String?) ?? 'The AI response was interrupted.');
      }
    }
    return out.toString();
  }

  void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
