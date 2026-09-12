import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// A rich text widget tailored for AI responses in the Yemen Home Business marketplace.
///
/// Features:
/// - Full markdown `**bold**` support with elegant typography.
/// - Automatic detection and highlighting of store names:
///   - Bold font weight (`FontWeight.w800`)
///   - Stylish underline (`TextDecoration.underline`)
///   - Slightly increased font size (+1.2sp)
///   - Storefront icon badge
///   - Interactive tap to redirect to store products/profile (`/store`)
/// - Beautiful bullet lists and numbered lists with custom badges.
/// - Graceful streaming support (handles unclosed markdown tokens mid-stream).
class AiMarkdownMessage extends StatelessWidget {
  final String text;
  final Map<String, String> storeNameToId;
  final void Function(String storeName, String storeId)? onStoreTap;
  final TextStyle? baseStyle;
  final bool isStreaming;

  const AiMarkdownMessage({
    super.key,
    required this.text,
    this.storeNameToId = const {},
    this.onStoreTap,
    this.baseStyle,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final defaultBaseStyle = TextStyle(
      fontSize: 14.5,
      height: 1.6,
      color: isDark ? Colors.grey.shade100 : const Color(0xFF2D3748),
      fontWeight: FontWeight.w400,
    );

    final effectiveBaseStyle = baseStyle ?? defaultBaseStyle;

    final lines = text.split('\n');
    final List<Widget> blockWidgets = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        // Spacing between paragraphs
        if (blockWidgets.isNotEmpty) {
          blockWidgets.add(const SizedBox(height: 6));
        }
        i++;
        continue;
      }

      // 1. Headers: ###, ##, #
      if (trimmed.startsWith('#')) {
        final level = trimmed.indexOf(RegExp(r'[^#]'));
        final headerText = trimmed.substring(level).trim();
        blockWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerText,
                    style: effectiveBaseStyle.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.purple.shade200 : primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 2. Numbered Lists: e.g. "1. ", "2. "
      final numMatch = RegExp(r'^(\d+)[\.\)]\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final number = numMatch.group(1)!;
        final content = numMatch.group(2)!;

        blockWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichText(
                    content,
                    context,
                    effectiveBaseStyle,
                    primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 3. Bullet Lists: e.g. "- ", "* ", "• "
      final bulletMatch = RegExp(r'^[\-\*\•]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!;

        blockWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.purple.shade300 : primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: _buildRichText(
                    content,
                    context,
                    effectiveBaseStyle,
                    primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 4. Regular Paragraphs
      blockWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildRichText(
            trimmed,
            context,
            effectiveBaseStyle,
            primaryColor,
          ),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blockWidgets,
    );
  }

  Widget _buildRichText(
    String rawLine,
    BuildContext context,
    TextStyle baseStyle,
    Color primaryColor,
  ) {
    final spans = _parseLineSpans(rawLine, context, baseStyle, primaryColor);
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  /// Parses markdown `**bold**` tokens and matches known store names
  /// applying the requested: bold + underline + font size increase + tap redirection.
  List<InlineSpan> _parseLineSpans(
    String line,
    BuildContext context,
    TextStyle baseStyle,
    Color primaryColor,
  ) {
    final List<InlineSpan> spans = [];

    // Sort known store names by length descending to match full names first
    final sortedStores = storeNameToId.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Split line by bold tokens: **bold text**
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in boldRegex.allMatches(line)) {
      // Text before the bold token
      if (match.start > lastIndex) {
        final normalSegment = line.substring(lastIndex, match.start);
        _appendSegmentWithStoreDetection(
          spans,
          normalSegment,
          baseStyle,
          false,
          sortedStores,
          primaryColor,
        );
      }

      // The bold token content
      final boldContent = match.group(1) ?? '';
      _appendSegmentWithStoreDetection(
        spans,
        boldContent,
        baseStyle.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A202C),
        ),
        true,
        sortedStores,
        primaryColor,
      );

      lastIndex = match.end;
    }

    // Remaining text after last bold match
    if (lastIndex < line.length) {
      final remaining = line.substring(lastIndex);
      if (isStreaming && remaining.startsWith('**')) {
        final dangling = remaining.substring(2);
        _appendSegmentWithStoreDetection(
          spans,
          dangling,
          baseStyle.copyWith(
            fontWeight: FontWeight.w800,
          ),
          true,
          sortedStores,
          primaryColor,
        );
      } else {
        _appendSegmentWithStoreDetection(
          spans,
          remaining,
          baseStyle,
          false,
          sortedStores,
          primaryColor,
        );
      }
    }

    return spans;
  }

  /// Scans a text segment for any known store names.
  /// If a store name is found, it formats it with:
  /// - Bold font weight (`FontWeight.w800`)
  /// - Underline (`TextDecoration.underline`)
  /// - Increased font size (+1.2sp)
  /// - Inline storefront icon badge
  /// - Tap gesture recognizer to navigate to store products
  void _appendSegmentWithStoreDetection(
    List<InlineSpan> spans,
    String segment,
    TextStyle currentStyle,
    bool isInsideBold,
    List<String> sortedStores,
    Color primaryColor,
  ) {
    if (segment.isEmpty) return;

    if (sortedStores.isEmpty) {
      spans.add(TextSpan(text: segment, style: currentStyle));
      return;
    }

    // Build regex pattern matching any known store name or "متجر [Name]"
    final pattern = sortedStores.map((s) {
      final escaped = RegExp.escape(s);
      return '(?:متجر\\s+["(]?)?$escaped[")]?';
    }).join('|');

    final storeRegex = RegExp('($pattern)', caseSensitive: false);
    int lastIdx = 0;

    for (final match in storeRegex.allMatches(segment)) {
      if (match.start > lastIdx) {
        spans.add(TextSpan(
          text: segment.substring(lastIdx, match.start),
          style: currentStyle,
        ));
      }

      final matchedRaw = match.group(0)!;
      // Resolve which store was matched
      String matchedStoreName = '';
      for (final s in sortedStores) {
        if (matchedRaw.contains(s)) {
          matchedStoreName = s;
          break;
        }
      }

      final storeId = storeNameToId[matchedStoreName] ?? '';

      // Inline storefront icon
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 3, right: 1),
            child: Icon(
              Icons.storefront_rounded,
              size: 14.5,
              color: primaryColor,
            ),
          ),
        ),
      );

      // Store name span: Underlined + Bold + Increased font size by +1.2
      final storeStyle = currentStyle.copyWith(
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
        decorationColor: primaryColor,
        decorationThickness: 1.8,
        decorationStyle: TextDecorationStyle.solid,
        fontSize: (currentStyle.fontSize ?? 14.5) + 1.2,
        color: primaryColor,
      );

      spans.add(
        TextSpan(
          text: matchedRaw,
          style: storeStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              HapticFeedback.lightImpact();
              if (onStoreTap != null) {
                onStoreTap!(matchedStoreName, storeId);
              } else if (storeId.isNotEmpty) {
                Get.toNamed('/store', arguments: {'id': storeId});
              }
            },
        ),
      );

      lastIdx = match.end;
    }

    if (lastIdx < segment.length) {
      spans.add(TextSpan(
        text: segment.substring(lastIdx),
        style: currentStyle,
      ));
    }
  }
}
