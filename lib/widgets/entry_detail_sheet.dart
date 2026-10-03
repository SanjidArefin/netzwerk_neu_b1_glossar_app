import 'package:flutter/material.dart';

import '../glossary.dart';
import '../services/glossary_service.dart';
import '../theme/app_theme.dart';

class EntryDetailSheet extends StatefulWidget {
  const EntryDetailSheet({
    super.key,
    required this.entries,
    required this.initialIndex,
    required this.onEdit,
  });

  final List<GlossaryEntry> entries;
  final int initialIndex;
  final Future<void> Function(int chapter, String word, String newMeaning)
  onEdit;

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

  void _openEditMeaning(GlossaryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _EditMeaningSheet(
          entry: entry,
          onSubmit: (newMeaning) =>
              widget.onEdit(entry.chapterNumber, entry.word, newMeaning),
          onClose: () => Navigator.of(sheetContext).pop(),
          onSaved: () {
            // Close the edit modal first, then the detail sheet behind it.
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          color: isDark
                              ? const Color(0xFF4B3D12)
                              : const Color(0xFFFFF3C0),
                          child: Text(
                            'Chapter ${entry.chapterNumber}',
                            style: const TextStyle(
                              color: Color(0xFF9A7600),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          // Trimmed padding: the chip plus the default button
                          // width overflows the 345px sheet content width.
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit meaning'),
                          onPressed: () => _openEditMeaning(entry),
                        ),
                      ],
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
                      tooltip: 'Previous word',
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
                      tooltip: 'Next word',
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

class _EditMeaningSheet extends StatefulWidget {
  const _EditMeaningSheet({
    required this.entry,
    required this.onSubmit,
    required this.onClose,
    required this.onSaved,
  });

  final GlossaryEntry entry;
  final Future<void> Function(String newMeaning) onSubmit;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<_EditMeaningSheet> createState() => _EditMeaningSheetState();
}

class _EditMeaningSheetState extends State<_EditMeaningSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _meaningController = TextEditingController(
    text: widget.entry.meaning,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_meaningController.text.trim());
      widget.onSaved();
    } on GlossaryException catch (exception) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = exception.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.entry.word,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chapter ${widget.entry.chapterNumber}',
                style: TextStyle(
                  color: themeMuted(theme),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meaningController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Meaning'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Meaning is required';
                  }
                  if (RegExp(r'[,;/]').hasMatch(value)) {
                    return 'No commas, semicolons or slashes';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
