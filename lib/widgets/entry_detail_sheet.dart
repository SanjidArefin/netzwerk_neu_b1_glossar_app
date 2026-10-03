import 'package:flutter/material.dart';

import '../glossary.dart';
import '../theme/app_theme.dart';

class EntryDetailSheet extends StatefulWidget {
  const EntryDetailSheet({
    super.key,
    required this.entries,
    required this.initialIndex,
  });

  final List<GlossaryEntry> entries;
  final int initialIndex;

  @override
  State<EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<EntryDetailSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _changeEntry(int change) {
    final nextIndex = _index + change;
    if (nextIndex < 0 || nextIndex >= widget.entries.length) {
      return;
    }
    setState(() => _index = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries[_index];
    final theme = Theme.of(context);
    final muted = themeMuted(theme);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.34,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        color: isDark
                            ? const Color(0xFF4B3D12)
                            : const Color(0xFFFFF3C0),
                        child: Text(
                          'Kapitel ${entry.chapterNumber}',
                          style: const TextStyle(
                            color: Color(0xFF9A7600),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SelectableText(
                      entry.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(height: 2, color: AppColors.green),
                    const SizedBox(height: 18),
                    Text(
                      'ENGLISH',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      entry.meaning,
                      style: const TextStyle(fontSize: 22, height: 1.3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    DetailArrowButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Vorheriges Wort',
                      enabled: _index > 0,
                      onPressed: () => _changeEntry(-1),
                    ),
                    Expanded(
                      child: Text(
                        '${_index + 1} / ${widget.entries.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DetailArrowButton(
                      icon: Icons.arrow_forward,
                      tooltip: 'Naechstes Wort',
                      enabled: _index < widget.entries.length - 1,
                      onPressed: () => _changeEntry(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DetailArrowButton extends StatelessWidget {
  const DetailArrowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}
