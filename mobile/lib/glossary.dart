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

  static List<GlossaryEntry> filter(
    GlossaryData glossary, {
    int? chapterNumber,
    String query = '',
  }) {
    final normalizedQuery = normalize(query.trim());
    final filtered = glossary.entries.where((entry) {
      final matchesChapter =
          chapterNumber == null || entry.chapterNumber == chapterNumber;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          normalize('${entry.word} ${entry.meaning}').contains(normalizedQuery);
      return matchesChapter && matchesQuery;
    }).toList();

    filtered.sort(compare);
    return filtered;
  }
}
