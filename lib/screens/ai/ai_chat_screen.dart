import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ai_chat_service.dart';
import '../../widgets/markdown_text.dart';

/// Shopping assistant chat (website: components/ModalAi/AiModal.jsx).
/// Streams replies from AppConfig.aiChatUrl.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.initialPrompt});

  /// Pre-filled question, e.g. from a product page.
  final String? initialPrompt;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _suggestions = [
    'Best phones under ₹20,000',
    'Gift ideas for my mom',
    'Compare wireless earbuds',
    'What to wear to a wedding?',
  ];

  final _service = AiChatService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  StreamSubscription<String>? _sub;
  bool _streaming = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) _input.text = widget.initialPrompt!;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _streaming) return;
    _input.clear();
    final history = [..._messages, ChatMessage(fromUser: true, text: text)];
    final reply = ChatMessage(fromUser: false, text: '');
    setState(() {
      _messages
        ..add(history.last)
        ..add(reply);
      _streaming = true;
    });
    _scrollToEnd();

    _sub = _service.send(history).listen(
      (chunk) {
        setState(() => reply.text += chunk);
        _scrollToEnd();
      },
      onError: (Object e) {
        setState(() {
          final msg = e is ApiException ? e.message : 'Something went wrong. Please try again.';
          reply.text = reply.text.isEmpty ? '⚠️ $msg' : '${reply.text}\n\n⚠️ $msg';
          _streaming = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          if (reply.text.isEmpty) reply.text = 'Sorry, I could not generate a reply. Please try again.';
          _streaming = false;
        });
      },
      cancelOnError: true,
    );
  }

  void _stop() {
    _sub?.cancel();
    _service.cancel();
    setState(() {
      _streaming = false;
      if (_messages.isNotEmpty && !_messages.last.fromUser && _messages.last.text.isEmpty) {
        _messages.last.text = '(stopped)';
      }
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const _AiAvatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ayira AI', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(_streaming ? 'typing…' : 'Your shopping assistant',
                    style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _stop();
                setState(_messages.clear);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _Welcome(onPick: _send, suggestions: _suggestions)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(
                      message: _messages[i],
                      typing: _streaming && i == _messages.length - 1 && _messages[i].text.isEmpty,
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about products…',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      enabledBorder:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(48, 48),
                  ),
                  tooltip: _streaming ? 'Stop' : 'Send',
                  onPressed: _streaming ? _stop : _send,
                  icon: Icon(_streaming ? Icons.stop_rounded : Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.brandYellow, borderRadius: BorderRadius.circular(size / 3)),
        child: Icon(Icons.auto_awesome_rounded, color: AppColors.navy, size: size * 0.55),
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick, required this.suggestions});
  final void Function(String) onPick;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const _AiAvatar(size: 72),
            const SizedBox(height: 18),
            Text('Hi! I\'m Ayira', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Ask me for product suggestions, comparisons, gift ideas or help with your shopping.',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [for (final s in suggestions) ActionChip(label: Text(s), onPressed: () => onPick(s))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.typing});
  final ChatMessage message;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = message.fromUser;
    final bg = user ? (isDark ? AppColors.brandYellow : AppColors.navy) : scheme.surface;
    final fg = user ? (isDark ? AppColors.navy : Colors.white) : scheme.onSurface;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: user ? null : Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
        ),
        child: typing
            ? const _TypingDots()
            : user
                ? Text(message.text, style: TextStyle(color: fg, height: 1.4))
                : MarkdownText(message.text, color: fg),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_c.value * 3) - i).clamp(0.0, 1.0);
            final up = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              transform: Matrix4.translationValues(0, -4 * up, 0),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.4 + 0.6 * up), shape: BoxShape.circle),
            );
          }),
        ),
      ),
    );
  }
}
