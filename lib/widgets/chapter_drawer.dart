import 'package:flutter/material.dart';

import '../glossary.dart';
import '../theme/app_theme.dart';
import 'brand_title.dart';

class ChapterDrawer extends StatelessWidget {
  const ChapterDrawer({
    super.key,
    required this.glossary,
    required this.selectedChapter,
    required this.onChapterChanged,
  });

  final GlossaryData glossary;
  final int? selectedChapter;
  final ValueChanged<int?> onChapterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = themeMuted(theme);
    return Drawer(
      width: 304,
      shape: const RoundedRectangleBorder(),
      backgroundColor: isDark ? AppColors.sidebar : theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: const BrandTitle(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 8),
              child: Row(
                children: [
                  Text(
                    'KAPITEL',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${glossary.totalEntries}',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ChapterTile(
              title: 'Alle Kapitel',
              count: glossary.totalEntries,
              selected: selectedChapter == null,
              onTap: () => onChapterChanged(null),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 2, bottom: 16),
                itemCount: glossary.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = glossary.chapters[index];
                  return ChapterTile(
                    title: chapter.title,
                    count: chapter.entries.length,
                    selected: selectedChapter == chapter.number,
                    onTap: () => onChapterChanged(chapter.number),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, color: AppColors.yellow),
                  const SizedBox(width: 8),
                  Text(
                    '${glossary.totalEntries} Woerter',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = themeMuted(theme);
    return Material(
      color: selected
          ? (isDark ? const Color(0xFF315B25) : const Color(0xFFE8FAD6))
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 45,
          padding: const EdgeInsets.only(left: 22, right: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.green : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? AppColors.green
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.green : muted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
