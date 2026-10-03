import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

const germanAlphabet = <String>[
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  'Ä',
  'Ö',
  'Ü',
];

class GlossaryEntry {
  const GlossaryEntry({
    required this.chapterNumber,
    required this.word,
    required this.meaning,
  });

  final int chapterNumber;
  final String word;
  final String meaning;

  String get id => '$chapterNumber-$word';
}

class GlossaryChapter {
  const GlossaryChapter({
    required this.number,
    required this.title,
    required this.entries,
  });

  final int number;
  final String title;
  final List<GlossaryEntry> entries;
}

class GlossaryData {
  const GlossaryData({
    required this.title,
    required this.totalEntries,
    required this.chapters,
  });

  final String title;
  final int totalEntries;
  final List<GlossaryChapter> chapters;

  List<GlossaryEntry> get entries => [
    for (final chapter in chapters) ...chapter.entries,
  ];

  static Future<GlossaryData> loadFromAsset([AssetBundle? bundle]) async {
    final source = await (bundle ?? rootBundle).loadString(
      'assets/data/glossary.json',
    );
    return GlossaryData.fromJsonString(source);
  }

  factory GlossaryData.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Glossary root must be an object.');
    }

    final title = decoded['title'];
    final totalEntries = decoded['totalEntries'];
    final rawChapters = decoded['chapters'];

    if (title is! String || totalEntries is! int || rawChapters is! List) {
      throw const FormatException('Glossary metadata is invalid.');
    }

    final chapters = <GlossaryChapter>[];
    final allRecords = <String>{};
    var importedEntries = 0;

    for (
      var chapterIndex = 0;
      chapterIndex < rawChapters.length;
      chapterIndex++
    ) {
      final rawChapter = rawChapters[chapterIndex];
      if (rawChapter is! Map<String, dynamic>) {
        throw const FormatException('Glossary chapter is invalid.');
      }

      final number = rawChapter['number'];
      final chapterTitle = rawChapter['title'];
      final rawEntries = rawChapter['entries'];
      if (number is! int || chapterTitle is! String || rawEntries is! List) {
        throw const FormatException('Glossary chapter data is invalid.');
      }

      if (number != chapterIndex + 1) {
        throw const FormatException('Glossary chapters must be in order.');
      }

      final entries = <GlossaryEntry>[];
      final chapterWords = <String>{};
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map<String, dynamic>) {
          throw const FormatException('Glossary entry is invalid.');
        }

        final word = rawEntry['word'];
        final meaning = rawEntry['meaning'];
        if (word is! String ||
            meaning is! String ||
            word.trim().isEmpty ||
            meaning.trim().isEmpty ||
            RegExp(r'[,;/]').hasMatch(meaning)) {
          throw const FormatException('Glossary entry has an invalid meaning.');
        }

        if (!chapterWords.add(word)) {
          throw const FormatException(
            'Glossary chapter contains duplicate words.',
          );
        }
        if (!allRecords.add('$number-$word')) {
          throw const FormatException('Glossary contains duplicate records.');
        }

        entries.add(
          GlossaryEntry(chapterNumber: number, word: word, meaning: meaning),
        );
      }

      for (var index = 1; index < entries.length; index++) {
        if (GlossarySearch.compare(entries[index - 1], entries[index]) > 0) {
          throw const FormatException(
            'Glossary chapter is not alphabetically sorted.',
          );
        }
      }

      importedEntries += entries.length;
      chapters.add(
        GlossaryChapter(number: number, title: chapterTitle, entries: entries),
      );
    }

    if (chapters.length != 12 || importedEntries != totalEntries) {
      throw const FormatException(
        'Glossary totals do not match the bundled data.',
      );
    }

    return GlossaryData(
      title: title,
      totalEntries: totalEntries,
      chapters: List.unmodifiable(chapters),
    );
  }
}

class GlossarySearch {
  const GlossarySearch._();

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  static String sortKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss');
  }

  static String firstLetter(GlossaryEntry entry) {
    return entry.word.substring(0, 1).toUpperCase();
  }

  static int compare(GlossaryEntry left, GlossaryEntry right) {
    final wordOrder = sortKey(left.word).compareTo(sortKey(right.word));
    if (wordOrder != 0) {
      return wordOrder;
    }
    return left.chapterNumber.compareTo(right.chapterNumber);
  }

  /// Standard iterative Levenshtein edit distance between two strings.
  static int levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  /// Returns a match score for [entry] against [normalizedQuery].
  /// 0 means no match. Higher is better.
  static int _scoreEntry(GlossaryEntry entry, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return 1;

    final word = normalize(entry.word);
    final meaning = normalize(entry.meaning);

    // Exact / prefix / contains (word preferred over meaning).
    if (word == normalizedQuery) return 100;
    if (word.startsWith(normalizedQuery)) return 80;
    if (meaning.startsWith(normalizedQuery)) return 60;
    if (word.contains(normalizedQuery)) return 40;
    if (meaning.contains(normalizedQuery)) return 20;

    // Typo tolerance: only run for reasonably long queries.
    if (normalizedQuery.length >= 4) {
      final wordDist = levenshtein(word, normalizedQuery);
      final maxWordDist = normalizedQuery.length <= 6 ? 1 : 2;
      if (wordDist <= maxWordDist) {
        return 30 - wordDist * 5;
      }
      // Also allow a prefix typo — "abnd" should match "abend".
      if (word.length >= normalizedQuery.length) {
        final prefix = word.substring(0, normalizedQuery.length);
        final prefixDist = levenshtein(prefix, normalizedQuery);
        if (prefixDist <= 1) {
          return 25 - prefixDist * 5;
        }
      }
    }

    return 0;
  }

  /// Filters glossary entries by chapter and query.
  ///
  /// When [query] is empty, results are returned in alphabetical order (as
  /// today). When [query] is non-empty, results are ordered by score — highest
  /// relevance first — then alphabetically within the same score.
  static List<GlossaryEntry> filter(
    GlossaryData glossary, {
    int? chapterNumber,
    String query = '',
  }) {
    final normalizedQuery = normalize(query.trim());

    final chapterFiltered = glossary.entries.where((entry) {
      return chapterNumber == null || entry.chapterNumber == chapterNumber;
    }).toList();

    if (normalizedQuery.isEmpty) {
      chapterFiltered.sort(compare);
      return chapterFiltered;
    }

    final scored = <({GlossaryEntry entry, int score})>[];
    for (final entry in chapterFiltered) {
      final score = _scoreEntry(entry, normalizedQuery);
      if (score > 0) {
        scored.add((entry: entry, score: score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return compare(a.entry, b.entry);
    });

    return [for (final item in scored) item.entry];
  }

  /// Returns the substring ranges in [text] that match [query] using
  /// the same normalization applied to entries. Returns empty list if no match.
  ///
  /// Because normalization can change string length (ä→ae), we do a pragmatic
  /// two-pass approach: first try to find the normalized query inside the
  /// normalized text and map back; if that fails, return an empty list.
  static List<(int, int)> matchRanges(String text, String query) {
    final normalizedQuery = normalize(query.trim());
    if (normalizedQuery.isEmpty) return const [];

    final lower = text.toLowerCase();
    final directIndex = lower.indexOf(query.trim().toLowerCase());
    if (directIndex >= 0) {
      return [(directIndex, directIndex + query.trim().length)];
    }

    // Umlaut-folded fallback: search normalized text, then find the closest
    // original range by walking the original and folding as we go.
    final normalizedText = normalize(text);
    final normalizedIndex = normalizedText.indexOf(normalizedQuery);
    if (normalizedIndex < 0) return const [];

    // Map normalized index back to original index by folding one character
    // at a time and counting.
    var normalizedPos = 0;
    var originalStart = -1;
    var originalEnd = text.length;
    for (var i = 0; i < text.length; i++) {
      if (normalizedPos == normalizedIndex && originalStart == -1) {
        originalStart = i;
      }
      final folded = normalize(text[i]);
      normalizedPos += folded.length;
      if (normalizedPos >= normalizedIndex + normalizedQuery.length) {
        originalEnd = i + 1;
        break;
      }
    }
    if (originalStart == -1) return const [];
    return [(originalStart, originalEnd)];
  }
}
