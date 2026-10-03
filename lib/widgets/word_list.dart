import 'package:flutter/material.dart';

import '../glossary.dart';
import '../theme/app_theme.dart';

class ResultSummary extends StatelessWidget {
  const ResultSummary({
    super.key,
    required this.count,
    required this.chapterLabel,
  });

  final int count;
  final String chapterLabel;

  @override
  Widget build(BuildContext context) {
    final muted = themeMuted(Theme.of(context));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'Eintrag' : 'Eintraege'}',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4B3D12)
                : const Color(0xFFFFF3C0),
            child: const Text(
              'A-Z',
              style: TextStyle(
                color: Color(0xFF9A7600),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Text(
            chapterLabel,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AlphabetJumpBar extends StatelessWidget {
  const AlphabetJumpBar({
    super.key,
    required this.availableLetters,
    required this.onLetterSelected,
  });

  final Set<String> availableLetters;
  final ValueChanged<String> onLetterSelected;

  @override
  Widget build(BuildContext context) {
    final muted = themeMuted(Theme.of(context));
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: germanAlphabet.length,
        separatorBuilder: (_, _) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          final letter = germanAlphabet[index];
          final available = availableLetters.contains(letter);
          return Tooltip(
            message: available
                ? 'Zu $letter springen'
                : 'Keine Woerter mit $letter',
            child: SizedBox(
              width: 31,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: available ? () => onLetterSelected(letter) : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: available
                            ? AppColors.blue
                            : muted.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LetterHeading extends StatelessWidget {
  const LetterHeading({super.key, required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceMuted
          : const Color(0xFFDDF4FF),
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class WordRow extends StatelessWidget {
  const WordRow({
    super.key,
    required this.entry,
    required this.showChapter,
    required this.onTap,
  });

  final GlossaryEntry entry;
  final bool showChapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = themeMuted(theme);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (showChapter) ...[
                const SizedBox(width: 12),
                Text(
                  'K${entry.chapterNumber}',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
