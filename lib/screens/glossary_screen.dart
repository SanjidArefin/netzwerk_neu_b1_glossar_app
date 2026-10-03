import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../glossary.dart';
import '../models/list_item.dart';
import '../services/glossary_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_title.dart';
import '../widgets/chapter_drawer.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/state_screens.dart';
import '../widgets/word_list.dart';

class GlossaryHome extends StatefulWidget {
  const GlossaryHome({
    super.key,
    required this.loader,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final Future<GlossaryData> Function() loader;
  final bool darkMode;
  final VoidCallback onThemeChanged;

  @override
  State<GlossaryHome> createState() => _GlossaryHomeState();
}

class _GlossaryHomeState extends State<GlossaryHome> {
  GlossaryData? _glossary;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.loader();
      if (!mounted) return;
      setState(() => _glossary = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _onGlossaryChanged(GlossaryData updated) {
    setState(() => _glossary = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return GlossaryLoadError(error: _error);
    }
    if (_glossary == null) {
      return const GlossaryLoading();
    }
    return GlossaryBrowser(
      glossary: _glossary!,
      onGlossaryChanged: _onGlossaryChanged,
      darkMode: widget.darkMode,
      onThemeChanged: widget.onThemeChanged,
    );
  }
}

class GlossaryBrowser extends StatefulWidget {
  const GlossaryBrowser({
    super.key,
    required this.glossary,
    required this.onGlossaryChanged,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final GlossaryData glossary;
  final void Function(GlossaryData) onGlossaryChanged;
  final bool darkMode;
  final VoidCallback onThemeChanged;

  @override
  State<GlossaryBrowser> createState() => _GlossaryBrowserState();
}

class _GlossaryBrowserState extends State<GlossaryBrowser> {
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  int? _chapterNumber;
  String _query = '';

  List<GlossaryEntry>? _cachedEntries;
  int? _cachedChapterForFilter;
  String? _cachedQueryForFilter;

  // Coalesces rapid keystrokes into a single filter+render. On a 9,435-entry
  // dataset, typing "abendessen" would otherwise trigger 10 full re-filters.
  Timer? _searchDebounce;

  @override
  void didUpdateWidget(GlossaryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An add/edit replaces the glossary object; the cached filter result is
    // keyed only on chapter + query, so it must be dropped explicitly.
    if (!identical(oldWidget.glossary, widget.glossary)) {
      _cachedEntries = null;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<GlossaryEntry> get _visibleEntries => _computeVisibleEntries();

  List<GlossaryEntry> _computeVisibleEntries() {
    if (_cachedEntries != null &&
        _cachedChapterForFilter == _chapterNumber &&
        _cachedQueryForFilter == _query) {
      return _cachedEntries!;
    }
    final entries = GlossarySearch.filter(
      widget.glossary,
      chapterNumber: _chapterNumber,
      query: _query,
    );
    _cachedEntries = entries;
    _cachedChapterForFilter = _chapterNumber;
    _cachedQueryForFilter = _query;
    return entries;
  }

  String get _chapterLabel {
    return _chapterNumber == null ? 'All Chapters' : 'Chapter $_chapterNumber';
  }

  void _selectChapter(int? chapterNumber) {
    setState(() => _chapterNumber = chapterNumber);
    _scrollToTop();
  }

  void _setQuery(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value);
      _scrollToTop();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _scrollToTop();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_itemScrollController.isAttached ||
          _visibleEntries.isEmpty) {
        return;
      }
      _itemScrollController.jumpTo(index: 0);
    });
  }

  void _jumpToLetter(String letter, Map<String, int> itemIndexes) {
    final index = itemIndexes[letter];
    if (index == null || !_itemScrollController.isAttached) {
      return;
    }
    _itemScrollController.scrollTo(
      index: index,
      alignment: 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _openEntryDetails(List<GlossaryEntry> entries, int entryIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntryDetailSheet(
        entries: entries,
        initialIndex: entryIndex,
        onEdit: (chapter, word, newMeaning) async {
          final updated = await GlossaryService().updateEntry(
            chapter: chapter,
            word: word,
            meaning: newMeaning,
          );
          widget.onGlossaryChanged(updated);
        },
      ),
    );
  }

  Future<void> _openAddWordSheet() async {
    final service = GlossaryService();
    final initialChapter = _chapterNumber ?? 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddWordSheet(
          initialChapter: initialChapter,
          onSubmit: (chapter, word, meaning) async {
            final updated = await service.addEntry(
              chapter: chapter,
              word: word,
              meaning: meaning,
            );
            widget.onGlossaryChanged(updated);
            if (mounted) {
              setState(() {
                _chapterNumber = chapter;
                _query = '';
                _searchController.clear();
              });
            }
            return updated;
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final listItems = buildListItems(entries);
    final letterIndexes = <String, int>{
      for (var index = 0; index < listItems.length; index++)
        if (listItems[index].letter != null) listItems[index].letter!: index,
    };
    final theme = Theme.of(context);
    final muted = themeMuted(theme);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddWordSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.canvas,
      ),
      drawer: ChapterDrawer(
        glossary: widget.glossary,
        selectedChapter: _chapterNumber,
        onChapterChanged: (chapterNumber) {
          Navigator.of(context).pop();
          _selectChapter(chapterNumber);
        },
      ),
      appBar: AppBar(
        titleSpacing: 4,
        title: const BrandTitle(),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.darkMode ? 'Light mode' : 'Dark mode',
            onPressed: widget.onThemeChanged,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chapterLabel.toUpperCase(),
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _query.trim().isEmpty ? 'Vocabulary' : 'Search Results',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _setQuery,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search word or meaning',
                prefixIcon: const Icon(Icons.search, color: AppColors.green),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: _clearQuery,
                      ),
              ),
            ),
          ),
          ResultSummary(count: entries.length, chapterLabel: _chapterLabel),
          AlphabetJumpBar(
            availableLetters: letterIndexes.keys.toSet(),
            onLetterSelected: (letter) => _jumpToLetter(letter, letterIndexes),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: entries.isEmpty
                ? const EmptyResults()
                : ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemCount: listItems.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      if (item.letter != null) {
                        return LetterHeading(letter: item.letter!);
                      }
                      return WordRow(
                        entry: item.entry!,
                        showChapter: _chapterNumber == null,
                        onTap: () =>
                            _openEntryDetails(entries, item.entryIndex!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddWordSheet extends StatefulWidget {
  const _AddWordSheet({
    required this.initialChapter,
    required this.onSubmit,
    required this.onClose,
  });

  final int initialChapter;
  final Future<GlossaryData> Function(int chapter, String word, String meaning)
  onSubmit;
  final VoidCallback onClose;

  @override
  State<_AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<_AddWordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  late int _chapter = widget.initialChapter;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _chapter,
        _wordController.text.trim(),
        _meaningController.text.trim(),
      );
      widget.onClose();
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
              const Text(
                'Add New Word',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _chapter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chapter'),
                items: [
                  for (var number = 1; number <= 12; number++)
                    DropdownMenuItem(
                      value: number,
                      child: Text('Chapter $number'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _chapter = value);
                  }
                },
                validator: (value) =>
                    value == null ? 'Chapter is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wordController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Word'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Word is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaningController,
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
