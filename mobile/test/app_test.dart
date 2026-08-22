import 'package:b1_glossar_mobile/glossary.dart';
import 'package:b1_glossar_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GlossaryData buildTestGlossary() {
  return const GlossaryData(
    title: 'B1 Glossar',
    totalEntries: 4,
    chapters: [
      GlossaryChapter(
        number: 1,
        title: 'Kapitel 1',
        entries: [
          GlossaryEntry(chapterNumber: 1, word: 'abend', meaning: 'evening'),
          GlossaryEntry(chapterNumber: 1, word: 'ärztin', meaning: 'doctor'),
        ],
      ),
      GlossaryChapter(
        number: 2,
        title: 'Kapitel 2',
        entries: [
          GlossaryEntry(chapterNumber: 2, word: 'kalt', meaning: 'cold'),
          GlossaryEntry(chapterNumber: 2, word: 'können', meaning: 'can'),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets(
    'defaults to dark mode and changes chapter, search, and details',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 851));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        B1GlossarApp(loader: () async => buildTestGlossary()),
      );
      await tester.pumpAndSettle();

      final homeContext = tester.element(find.text('Wortschatz'));
      expect(Theme.of(homeContext).brightness, Brightness.dark);
      expect(find.text('abend'), findsOneWidget);
      expect(find.text('K1'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kapitel 2'));
      await tester.pumpAndSettle();

      expect(find.text('K2'), findsNothing);
      expect(find.text('können'), findsOneWidget);

      final searchField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Wort oder Bedeutung suchen',
      );
      await tester.enterText(searchField, 'koennen');
      await tester.pumpAndSettle();
      expect(find.text('können'), findsOneWidget);
      expect(find.text('kalt'), findsNothing);

      await tester.tap(find.text('können'));
      await tester.pumpAndSettle();
      expect(find.text('ENGLISH'), findsOneWidget);
      expect(find.text('can'), findsNWidgets(2));
    },
  );

  testWidgets('theme toggle enables light mode', (tester) async {
    await tester.pumpWidget(
      B1GlossarApp(loader: () async => buildTestGlossary()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hellmodus'));
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.text('Wortschatz'));
    expect(Theme.of(homeContext).brightness, Brightness.light);
  });
}
