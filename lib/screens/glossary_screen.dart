import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../glossary.dart';
import '../models/list_item.dart';
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
  late final Future<GlossaryData> _glossary;

  @override
  void initState() {
    super.initState();
    _glossary = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GlossaryData>(
      future: _glossary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GlossaryLoading();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return GlossaryLoadError(error: snapshot.error);
        }
        return GlossaryBrowser(
          glossary: snapshot.data!,
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
        );
      },
    );
  }
}

class GlossaryBrowser extends StatefulWidget {
  const GlossaryBrowser({
    super.key,
    required this.glossary,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final GlossaryData glossary;
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
    return _chapterNumber == null ? 'Alle Kapitel' : 'Kapitel $_chapterNumber';
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
      builder: (_) =>
          EntryDetailSheet(entries: entries, initialIndex: entryIndex),
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
            tooltip: widget.darkMode ? 'Hellmodus' : 'Dunkelmodus',
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
                    _query.trim().isEmpty ? 'Wortschatz' : 'Suchergebnisse',
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
                hintText: 'Wort oder Bedeutung suchen',
                prefixIcon: const Icon(Icons.search, color: AppColors.green),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Suche leeren',
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
