import 'package:flutter/material.dart';

/// Minimal Markdown renderer for AI replies: headings, bullet / numbered
/// lists, **bold**, *italic* and `code`. Good enough for chat answers
/// without pulling in a full Markdown package.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  static final _inline = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*\s][^*]*\*)');
  static final _numbered = RegExp(r'^(\d+)[.)]\s+');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final base = t.bodyMedium!.copyWith(color: color, height: 1.45);
    final children = <Widget>[];

    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
      } else if (trimmed.startsWith('#')) {
        final content = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text.rich(_spans(content, base.copyWith(fontWeight: FontWeight.w700, fontSize: 16))),
        ));
      } else if (RegExp(r'^[-*•]\s+').hasMatch(trimmed)) {
        children.add(_listItem('•', trimmed.replaceFirst(RegExp(r'^[-*•]\s+'), ''), base, indent: line.length - trimmed.length));
      } else if (_numbered.hasMatch(trimmed)) {
        final n = _numbered.firstMatch(trimmed)!.group(1);
        children.add(_listItem('$n.', trimmed.replaceFirst(_numbered, ''), base));
      } else if (RegExp(r'^-{3,}$').hasMatch(trimmed)) {
        children.add(const Divider(height: 16));
      } else {
        children.add(Text.rich(_spans(line, base)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _listItem(String marker, String content, TextStyle base, {int indent = 0}) => Padding(
        padding: EdgeInsets.only(left: 4.0 + indent * 4, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20, child: Text(marker, style: base.copyWith(fontWeight: FontWeight.w700))),
            Expanded(child: Text.rich(_spans(content, base))),
          ],
        ),
      );

  TextSpan _spans(String input, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(input)) {
      if (m.start > last) spans.add(TextSpan(text: input.substring(last, m.start)));
      final token = m.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(fontFamily: 'monospace', backgroundColor: base.color?.withValues(alpha: 0.08)),
        ));
      } else {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = m.end;
    }
    if (last < input.length) spans.add(TextSpan(text: input.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
