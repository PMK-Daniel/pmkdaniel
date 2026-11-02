import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ReadingBlockKind { title, heading, label, paragraph, quote, listItem }

class ReadingBlock {
  const ReadingBlock(this.kind, this.text, {this.marker});
  final ReadingBlockKind kind;
  final String text;
  final String? marker;
}

final _loneMarker = RegExp(r'^(?:[•\-–·]|\d{1,2}[.)]|[A-Za-z][.)])$');
final _sentenceEnd = RegExp(r'[.?!,;…]$');

bool _isTitle(String text) {
  if (text.contains('\n') || text.length > 90) return false;
  final letters = text.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
  return letters.length >= 6 && letters == letters.toUpperCase();
}

bool _isQuote(String text) =>
    (text.startsWith('“') || text.startsWith('"')) && text.length < 600;

bool _isHeading(String text) {
  if (text.contains('\n') || text.length > 90) return false;
  if (text.startsWith('“') || text.startsWith('"') || text.startsWith('☐')) {
    return false;
  }
  if (RegExp(r'^\d{1,2}[.)]\s').hasMatch(text)) return false;
  if (_sentenceEnd.hasMatch(text)) return false;
  return text.split(RegExp(r'\s+')).length <= 14;
}

/// Splits extracted PDF text into presentation blocks without altering the
/// wording. Only the way each paragraph is displayed is inferred.
List<ReadingBlock> parseReadingBlocks(String page) {
  final parts = page
      .split(RegExp(r'\n[ \t]*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  final blocks = <ReadingBlock>[];
  String? pendingMarker;
  for (final part in parts) {
    if (_loneMarker.hasMatch(part)) {
      pendingMarker = part;
      continue;
    }
    if (pendingMarker != null) {
      final marker = pendingMarker;
      pendingMarker = null;
      final bullet = RegExp(r'^[•\-–·]$').hasMatch(marker);
      blocks.add(
        ReadingBlock(
          ReadingBlockKind.listItem,
          part,
          marker: bullet ? '•' : marker,
        ),
      );
    } else if (_isTitle(part)) {
      blocks.add(ReadingBlock(ReadingBlockKind.title, part));
    } else if (_isQuote(part)) {
      blocks.add(ReadingBlock(ReadingBlockKind.quote, part));
    } else if (_isHeading(part)) {
      final label =
          part.endsWith(':') && part.split(RegExp(r'\s+')).length <= 3;
      blocks.add(
        ReadingBlock(
          label ? ReadingBlockKind.label : ReadingBlockKind.heading,
          part,
        ),
      );
    } else {
      blocks.add(ReadingBlock(ReadingBlockKind.paragraph, part));
    }
  }
  if (pendingMarker != null) {
    blocks.add(ReadingBlock(ReadingBlockKind.paragraph, pendingMarker));
  }
  return blocks;
}

/// Readable, responsive presentation of one extracted document page.
class CircleReadingBody extends StatelessWidget {
  const CircleReadingBody({super.key, required this.text});
  final String text;

  static const _body = TextStyle(
    fontSize: 17,
    height: 1.7,
    color: AppTheme.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = parseReadingBlocks(text);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final first = i == 0;
      switch (block.kind) {
        case ReadingBlockKind.title:
          children.add(
            Semantics(
              header: true,
              child: Padding(
                padding: EdgeInsets.only(top: first ? 0 : 28, bottom: 8),
                child: Text(
                  block.text,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondaryDark,
                  ),
                ),
              ),
            ),
          );
        case ReadingBlockKind.heading:
          children.add(
            Semantics(
              header: true,
              child: Padding(
                padding: EdgeInsets.only(top: first ? 0 : 28, bottom: 10),
                child: Text(
                  block.text,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
          );
        case ReadingBlockKind.label:
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(
                block.text,
                style: _body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          );
        case ReadingBlockKind.quote:
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppTheme.warmSurface,
                  border: Border(
                    left: BorderSide(color: AppTheme.secondaryDark, width: 3),
                  ),
                ),
                child: SelectableText(
                  block.text,
                  style: _body.copyWith(fontSize: 16),
                ),
              ),
            ),
          );
        case ReadingBlockKind.listItem:
          children.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      block.marker ?? '•',
                      style: _body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(block.text, style: _body)),
                ],
              ),
            ),
          );
        case ReadingBlockKind.paragraph:
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SelectableText(block.text, style: _body),
            ),
          );
      }
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
