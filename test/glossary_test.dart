import 'dart:io';

import 'package:b1_glossar_mobile/glossary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled mobile data matches the canonical Electron data', () async {
    final canonical = await File('../backend/data/glossary.json')
        .readAsString();
    final mobile = await File('assets/data/glossary.json').readAsString();

    expect(mobile, canonical);

    final glossary = GlossaryData.fromJsonString(mobile);
    expect(glossary.chapters, hasLength(12));
    expect(glossary.totalEntries, 9435);
    expect(glossary.entries, hasLength(9435));
  });

  test('search handles German spelling alternatives and sorts results', () {
    const glossary = GlossaryData(
      title: 'Test',
      totalEntries: 4,
      chapters: [
        GlossaryChapter(
          number: 1,
          title: 'Kapitel 1',
          entries: [
            GlossaryEntry(chapterNumber: 1, word: 'zwei', meaning: 'two'),
            GlossaryEntry(chapterNumber: 1, word: 'ärztin', meaning: 'doctor'),
          ],
        ),
        GlossaryChapter(
          number: 2,
          title: 'Kapitel 2',
          entries: [
            GlossaryEntry(chapterNumber: 2, word: 'groß', meaning: 'large'),
            GlossaryEntry(chapterNumber: 2, word: 'abend', meaning: 'evening'),
          ],
        ),
      ],
    );

    expect(
      GlossarySearch.filter(glossary, query: 'aerztin').single.word,
      'ärztin',
    );
    expect(GlossarySearch.filter(glossary, query: 'gross').single.word, 'groß');
    expect(
      GlossarySearch.filter(
        glossary,
        chapterNumber: 2,
      ).map((entry) => entry.word),
      ['abend', 'groß'],
    );
  });

  test('malformed and duplicate data is rejected', () {
    const duplicate = '''
      {"title":"Test","totalEntries":2,"chapters":[
        {"number":1,"title":"Kapitel 1","entries":[
          {"word":"abend","meaning":"evening"},
          {"word":"abend","meaning":"night"}
        ]}
      ]}
    ''';

    expect(() => GlossaryData.fromJsonString(duplicate), throwsFormatException);
  });
}
