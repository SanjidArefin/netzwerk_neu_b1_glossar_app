import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'glossary.dart';

const _canvas = Color(0xFF131F24);
const _surface = Color(0xFF202F36);
const _sidebar = Color(0xFF17262D);
const _surfaceMuted = Color(0xFF2A3A43);
const _inputSurface = Color(0xFF26363E);
const _ink = Color(0xFFF7F7F7);
const _muted = Color(0xFFAFBFC5);
const _line = Color(0xFF3A4B55);
const _green = Color(0xFF58CC02);
const _blue = Color(0xFF1CB0F6);
const _yellow = Color(0xFFFFC800);
const _red = Color(0xFFFF4B4B);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _sidebar,
      systemNavigationBarColor: _canvas,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const B1GlossarApp());
}

class B1GlossarApp extends StatefulWidget {
  const B1GlossarApp({super.key, this.loader});

  final Future<GlossaryData> Function()? loader;

  @override
  State<B1GlossarApp> createState() => _B1GlossarAppState();
}

class _B1GlossarAppState extends State<B1GlossarApp> {
  var _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B1 Glossar',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_darkMode ? Brightness.dark : Brightness.light),
      home: _GlossaryHome(
        loader: widget.loader ?? () => GlossaryData.loadFromAsset(),
        darkMode: _darkMode,
        onThemeChanged: () => setState(() => _darkMode = !_darkMode),
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? _surface : const Color(0xFFFFFFFF);
  final canvas = isDark ? _canvas : const Color(0xFFF7F7F7);
  final ink = isDark ? _ink : const Color(0xFF263238);
  final muted = isDark ? _muted : const Color(0xFF66757F);
  final line = isDark ? _line : const Color(0xFFD9E1E4);
  final input = isDark ? _inputSurface : const Color(0xFFFFFFFF);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: _green,
      onPrimary: _canvas,
      secondary: _blue,
      onSecondary: _canvas,
      error: _red,
      onError: _ink,
      surface: surface,
      onSurface: ink,
      outline: line,
    ),
    scaffoldBackgroundColor: canvas,
    dividerColor: line,
    textTheme: ThemeData(brightness: brightness).textTheme
        .apply(bodyColor: ink, displayColor: ink),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? _sidebar : surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
    ),
  );
}

class _GlossaryHome extends StatefulWidget {
  const _GlossaryHome({
    required this.loader,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final Future<GlossaryData> Function() loader;
  final bool darkMode;
  final VoidCallback onThemeChanged;

  @override
  State<_GlossaryHome> createState() => _GlossaryHomeState();
}

class _GlossaryHomeState extends State<_GlossaryHome> {
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
          return const _GlossaryLoading();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _GlossaryLoadError(error: snapshot.error);
        }
        return _GlossaryBrowser(
          glossary: snapshot.data!,
          darkMode: widget.darkMode,
          onThemeChanged: widget.onThemeChanged,
        );
      },
    );
  }
}

class _GlossaryBrowser extends StatefulWidget {
  const _GlossaryBrowser({
    required this.glossary,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final GlossaryData glossary;
  final bool darkMode;
  final VoidCallback onThemeChanged;

  @override
  State<_GlossaryBrowser> createState() => _GlossaryBrowserState();
}

class _GlossaryBrowserState extends State<_GlossaryBrowser> {
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();
  int? _chapterNumber;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GlossaryEntry> get _visibleEntries => GlossarySearch.filter(
    widget.glossary,
    chapterNumber: _chapterNumber,
    query: _query,
  );

  String get _chapterLabel {
    return _chapterNumber == null ? 'Alle Kapitel' : 'Kapitel $_chapterNumber';
  }

  void _selectChapter(int? chapterNumber) {
    setState(() => _chapterNumber = chapterNumber);
    _scrollToTop();
  }

  void _setQuery(String value) {
    setState(() => _query = value);
    _scrollToTop();
  }

  void _clearQuery() {
    _searchController.clear();
    _setQuery('');
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
          _EntryDetailSheet(entries: entries, initialIndex: entryIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final listItems = _buildListItems(entries);
    final letterIndexes = <String, int>{
      for (var index = 0; index < listItems.length; index++)
        if (listItems[index].letter != null) listItems[index].letter!: index,
    };
    final theme = Theme.of(context);
    final muted = _themeMuted(theme);

    return Scaffold(
      drawer: _ChapterDrawer(
        glossary: widget.glossary,
        selectedChapter: _chapterNumber,
        onChapterChanged: (chapterNumber) {
          Navigator.of(context).pop();
          _selectChapter(chapterNumber);
        },
      ),
      appBar: AppBar(
        titleSpacing: 4,
        title: const _BrandTitle(),
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
                prefixIcon: const Icon(Icons.search, color: _green),
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
          _ResultSummary(count: entries.length, chapterLabel: _chapterLabel),
          _AlphabetJumpBar(
            availableLetters: letterIndexes.keys.toSet(),
            onLetterSelected: (letter) => _jumpToLetter(letter, letterIndexes),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: entries.isEmpty
                ? const _EmptyResults()
                : ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemCount: listItems.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      if (item.letter != null) {
                        return _LetterHeading(letter: item.letter!);
                      }
                      return _WordRow(
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

Color _themeMuted(ThemeData theme) {
  return theme.brightness == Brightness.dark ? _muted : const Color(0xFF66757F);
}

List<_ListItem> _buildListItems(List<GlossaryEntry> entries) {
  final items = <_ListItem>[];
  var previousLetter = '';
  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    final letter = GlossarySearch.firstLetter(entry);
    if (letter != previousLetter) {
      items.add(_ListItem.heading(letter));
      previousLetter = letter;
    }
    items.add(_ListItem.entry(entry, index));
  }
  return items;
}

class _ListItem {
  const _ListItem.heading(this.letter) : entry = null, entryIndex = null;

  const _ListItem.entry(this.entry, this.entryIndex) : letter = null;

  final String? letter;
  final GlossaryEntry? entry;
  final int? entryIndex;
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _green,
            border: Border.all(color: const Color(0xFF89E219), width: 3),
          ),
          child: const Text(
            'B1',
            style: TextStyle(
              color: _canvas,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NETZWERK NEU',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
            Text(
              'Glossar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.count, required this.chapterLabel});

  final int count;
  final String chapterLabel;

  @override
  Widget build(BuildContext context) {
    final muted = _themeMuted(Theme.of(context));
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

class _AlphabetJumpBar extends StatelessWidget {
  const _AlphabetJumpBar({
    required this.availableLetters,
    required this.onLetterSelected,
  });

  final Set<String> availableLetters;
  final ValueChanged<String> onLetterSelected;

  @override
  Widget build(BuildContext context) {
    final muted = _themeMuted(Theme.of(context));
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
                            ? _blue
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

class _LetterHeading extends StatelessWidget {
  const _LetterHeading({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).brightness == Brightness.dark
          ? _surfaceMuted
          : const Color(0xFFDDF4FF),
      child: Text(
        letter,
        style: const TextStyle(
          color: _blue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
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
    final muted = _themeMuted(theme);
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

class _ChapterDrawer extends StatelessWidget {
  const _ChapterDrawer({
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
    final muted = _themeMuted(theme);
    return Drawer(
      width: 304,
      shape: const RoundedRectangleBorder(),
      backgroundColor: isDark ? _sidebar : theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: const _BrandTitle(),
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
            _ChapterTile(
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
                  return _ChapterTile(
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
                  Container(width: 8, height: 8, color: _yellow),
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

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
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
    final muted = _themeMuted(theme);
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
                color: selected ? _green : Colors.transparent,
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
                    color: selected ? _green : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? _green : muted,
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

class _EntryDetailSheet extends StatefulWidget {
  const _EntryDetailSheet({required this.entries, required this.initialIndex});

  final List<GlossaryEntry> entries;
  final int initialIndex;

  @override
  State<_EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<_EntryDetailSheet> {
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
    final muted = _themeMuted(theme);
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
                    Container(height: 2, color: _green),
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
                    _DetailArrowButton(
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
                    _DetailArrowButton(
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

class _DetailArrowButton extends StatelessWidget {
  const _DetailArrowButton({
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

class _GlossaryLoading extends StatelessWidget {
  const _GlossaryLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoadingBrand(),
            SizedBox(height: 22),
            CircularProgressIndicator(color: _green),
          ],
        ),
      ),
    );
  }
}

class _LoadingBrand extends StatelessWidget {
  const _LoadingBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _green,
        border: Border.all(color: const Color(0xFF89E219), width: 4),
      ),
      child: const Text(
        'B1',
        style: TextStyle(
          color: _canvas,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlossaryLoadError extends StatelessWidget {
  const _GlossaryLoadError({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final muted = _themeMuted(Theme.of(context));
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _red, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Glossardaten konnten nicht geladen werden.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final muted = _themeMuted(Theme.of(context));
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 36, color: muted),
          const SizedBox(height: 12),
          Text(
            'Keine passenden Woerter gefunden.',
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
