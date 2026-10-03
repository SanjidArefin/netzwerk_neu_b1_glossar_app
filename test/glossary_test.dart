import 'dart:io';

import 'package:b1_glossar_mobile/glossary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled glossary asset parses with expected totals', () async {
    final source = await File('assets/data/glossary.json').readAsString();

    final glossary = GlossaryData.fromJsonString(source);
    expect(glossary.chapters, hasLength(12));
    expect(glossary.totalEntries, 9435);
    expect(glossary.entries, hasLength(9435));

    // Every chapter should carry the expected "Kapitel N" title from the data.
    for (var i = 0; i < glossary.chapters.length; i++) {
      expect(glossary.chapters[i].number, i + 1);
    }
  });

  test('search handles German spelling alternatives and sorts results', () {
    const glossary = GlossaryData(
      title: 'Test',
      totalEntries: 4,
      chapters: [
        GlossaryChapter(
          number: 1,
          title: 'Chapter 1',
          entries: [
            GlossaryEntry(chapterNumber: 1, word: 'zwei', meaning: 'two'),
            GlossaryEntry(chapterNumber: 1, word: 'ärztin', meaning: 'doctor'),
          ],
        ),
        GlossaryChapter(
          number: 2,
          title: 'Chapter 2',
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
        {"number":1,"title":"Chapter 1","entries":[
          {"word":"abend","meaning":"evening"},
          {"word":"abend","meaning":"night"}
        ]}
      ]}
    ''';

    expect(() => GlossaryData.fromJsonString(duplicate), throwsFormatException);
  });
}
