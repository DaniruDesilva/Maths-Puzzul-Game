class WordDictionary {
  WordDictionary._();
  static final WordDictionary instance = WordDictionary._();

  bool get isLoaded => true;

  Future<void> load() async {
    // Dictionary deprecated; math engine uses arithmetic expressions.
  }

  bool contains(String word) => false;
}
