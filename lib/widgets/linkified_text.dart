import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_holidays/theme/app_colors.dart';

/// A Text widget that detects URLs and makes them tappable.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  static final _urlRegex = RegExp(
    r'https?://[^\s<>\]\)]+',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose old recognizers before rebuilding
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = baseStyle.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _urlRegex.allMatches(widget.text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _launch(url);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: recognizer,
      ));
      lastEnd = match.end;
    }

    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // No URLs found — plain text
    if (spans.isEmpty) {
      return Text(
        widget.text,
        style: baseStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
