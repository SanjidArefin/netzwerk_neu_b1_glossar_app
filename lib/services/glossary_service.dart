import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../glossary.dart';

/// Loads the glossary from a writable copy in the app documents directory.
///
/// On first launch the bundled asset `assets/data/glossary.json` is copied
/// to `<documents>/glossary.json`. All subsequent reads and writes go to that
/// copy. The asset is never modified.
class GlossaryService {
  static const _assetPath = 'assets/data/glossary.json';
  static const _fileName = 'glossary.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      final seed = await rootBundle.loadString(_assetPath);
      await file.writeAsString(seed);
    }
    _cachedFile = file;
    return file;
  }

  /// Reads the current glossary from disk.
  Future<GlossaryData> load() async {
    final file = await _file();
    final source = await file.readAsString();
    return GlossaryData.fromJsonString(source);
  }

  /// Adds a new entry to the given chapter. Throws [GlossaryException] with a
  /// user-friendly message on validation failure.
  Future<GlossaryData> addEntry({
    required int chapter,
    required String word,
    required String meaning,
  }) async {
    final glossary = await load();
    final cleanWord = _normalize(word);
    final cleanMeaning = _normalize(meaning);
    _validateWord(cleanWord);
    _validateMeaning(cleanMeaning);
    _ensureChapterExists(glossary, chapter);
    _ensureNotDuplicate(glossary, cleanWord);

    final raw = await _readRaw();
    final chapters = raw['chapters'] as List;
    final target = chapters.firstWhere((c) => c['number'] == chapter);
    final entries = target['entries'] as List;
    entries.add({'word': cleanWord, 'meaning': cleanMeaning});
    // Sort with the same key the strict parser validates (GlossarySearch
    // sortKey, where "ä" sorts as "a"), NOT plain toLowerCase — otherwise
    // umlaut entries land out of order and load() rejects the whole file.
    entries.sort(
      (a, b) =>
          GlossarySearch.sortKey(a['word'] as String)
              .compareTo(GlossarySearch.sortKey(b['word'] as String)),
    );
    raw['totalEntries'] = chapters.fold<int>(
      0,
      (sum, c) => sum + (c['entries'] as List).length,
    );

    await _writeRaw(raw);
    return load();
  }

  /// Updates an existing entry's meaning. Chapter and word identify the entry
  /// and are locked. Throws [GlossaryException] on validation failure.
  Future<GlossaryData> updateEntry({
    required int chapter,
    required String word,
    required String meaning,
  }) async {
    final glossary = await load();
    final cleanWord = _normalize(word);
    final cleanMeaning = _normalize(meaning);
    _validateMeaning(cleanMeaning);
    _ensureChapterExists(glossary, chapter);

    final raw = await _readRaw();
    final chapters = raw['chapters'] as List;
    final target = chapters.firstWhere((c) => c['number'] == chapter);
    final entries = target['entries'] as List;
    final matchIndex = entries.indexWhere((e) => e['word'] == cleanWord);
    if (matchIndex == -1) {
      throw const GlossaryException('Word not found in this chapter.');
    }
    (entries[matchIndex] as Map)['meaning'] = cleanMeaning;

    await _writeRaw(raw);
    return load();
  }

  /// Deletes a single entry identified by chapter + word.
  /// Throws [GlossaryException] if not found.
  Future<GlossaryData> deleteEntry({
    required int chapter,
    required String word,
  }) async {
    final glossary = await load();
    _ensureChapterExists(glossary, chapter);

    final raw = await _readRaw();
    final chapters = raw['chapters'] as List;
    final target = chapters.firstWhere((c) => c['number'] == chapter);
    final entries = target['entries'] as List;
    // removeWhere returns void, so the match count must be taken first.
    final matches = entries.where((e) => e['word'] == word).length;
    if (matches == 0) {
      throw GlossaryException('"$word" was not found in chapter $chapter.');
    }
    entries.removeWhere((e) => e['word'] == word);

    raw['totalEntries'] = chapters.fold<int>(
      0,
      (sum, c) => sum + (c['entries'] as List).length,
    );
    await _writeRaw(raw);
    return load();
  }

  /// Deletes multiple entries at once.
  /// Each item in [compositeIds] is "$chapter|$word".
  /// Silently skips entries that are not found; throws if none were removed.
  Future<GlossaryData> deleteEntries(List<String> compositeIds) async {
    if (compositeIds.isEmpty) {
      throw const GlossaryException('No entries selected.');
    }

    final raw = await _readRaw();
    final chapters = raw['chapters'] as List;
    var removed = 0;

    for (final id in compositeIds) {
      final sep = id.indexOf('|');
      if (sep == -1) continue;
      final chapter = int.tryParse(id.substring(0, sep));
      final word = id.substring(sep + 1);
      if (chapter == null) continue;

      final target = chapters.firstWhere(
        (c) => c['number'] == chapter,
        orElse: () => null,
      );
      if (target == null) continue;
      final entries = target['entries'] as List;
      final matches = entries.where((e) => e['word'] == word).length;
      if (matches == 0) continue;
      entries.removeWhere((e) => e['word'] == word);
      removed += matches;
    }

    if (removed == 0) {
      throw const GlossaryException('No entries were removed.');
    }

    raw['totalEntries'] = chapters.fold<int>(
      0,
      (sum, c) => sum + (c['entries'] as List).length,
    );
    await _writeRaw(raw);
    return load();
  }

  Future<Map<String, dynamic>> _readRaw() async {
    final file = await _file();
    final source = await file.readAsString();
    return jsonDecode(source) as Map<String, dynamic>;
  }

  Future<void> _writeRaw(Map<String, dynamic> raw) async {
    final file = await _file();
    // Write to a temp file and rename for atomicity.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
    await tmp.rename(file.path);
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  void _validateWord(String word) {
    if (word.isEmpty) {
      throw const GlossaryException('Word must not be empty.');
    }
    if (word.length > 80) {
      throw const GlossaryException('Word is too long (max 80 characters).');
    }
  }

  void _validateMeaning(String meaning) {
    if (meaning.isEmpty) {
      throw const GlossaryException('Meaning must not be empty.');
    }
    if (meaning.length > 160) {
      throw const GlossaryException(
        'Meaning is too long (max 160 characters).',
      );
    }
    if (RegExp(r'[,;/]').hasMatch(meaning)) {
      throw const GlossaryException(
        'Meaning must not contain commas, semicolons or slashes.',
      );
    }
  }

  void _ensureChapterExists(GlossaryData glossary, int chapter) {
    if (!glossary.chapters.any((c) => c.number == chapter)) {
      throw GlossaryException('Chapter $chapter does not exist.');
    }
  }

  void _ensureNotDuplicate(GlossaryData glossary, String word) {
    final lowered = word.toLowerCase();
    for (final chapter in glossary.chapters) {
      for (final entry in chapter.entries) {
        if (entry.word.toLowerCase() == lowered) {
          throw GlossaryException('"$word" is already in the glossary.');
        }
      }
    }
  }
}

class GlossaryException implements Exception {
  const GlossaryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Encodes a chapter+word pair into the id format used by [GlossaryService.deleteEntries].
String glossaryCompositeId(int chapter, String word) => '$chapter|$word';
