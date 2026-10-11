import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:english_words/english_words.dart' as ew;

/// Full English dictionary (~168k words) used to validate bonus words.
///
/// Loaded once from `assets/words/dictionary.txt` on a background isolate.
/// Until loading finishes, falls back to the bundled top-5000 common words
/// so validation never blocks gameplay.
class WordDictionary {
  WordDictionary._();
  static final WordDictionary instance = WordDictionary._();

  Set<String>? _words;
  Future<void>? _loading;
  static final Set<String> _fallback = ew.all.map((w) => w.toLowerCase()).toSet();

  bool get isLoaded => _words != null;

  Future<void> load() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/words/dictionary.txt');
      _words = await compute(_parse, raw);
    } catch (e) {
      debugPrint('WordDictionary: failed to load dictionary ($e), using fallback list.');
      _words = _fallback;
    }
  }

  static Set<String> _parse(String raw) {
    final set = <String>{};
    for (final line in raw.split('\n')) {
      final w = line.trim();
      if (w.isNotEmpty) set.add(w);
    }
    return set;
  }

  /// Returns true if [word] (any case) is a real English word.
  bool contains(String word) {
    final w = word.toLowerCase();
    return (_words ?? _fallback).contains(w);
  }
}
