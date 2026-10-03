import '../glossary.dart';

class ListItem {
  const ListItem.heading(this.letter) : entry = null, entryIndex = null;

  const ListItem.entry(this.entry, this.entryIndex) : letter = null;

  final String? letter;
  final GlossaryEntry? entry;
  final int? entryIndex;
}

List<ListItem> buildListItems(List<GlossaryEntry> entries) {
  final items = <ListItem>[];
  var previousLetter = '';
  for (var index = 0; index < entries.length; index++) {
    final entry = entries[index];
    final letter = GlossarySearch.firstLetter(entry);
    if (letter != previousLetter) {
      items.add(ListItem.heading(letter));
      previousLetter = letter;
    }
    items.add(ListItem.entry(entry, index));
  }
  return items;
}
