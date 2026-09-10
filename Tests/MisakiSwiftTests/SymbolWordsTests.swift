import Testing
@testable import MisakiSwift

// `Lexicon.symbolSet` maps %, &, + and @ to spoken words, but the tagger marks
// them as punctuation and the punctuation branch in EnglishG2P fired first —
// so the lexicon never saw them and they came out as punctuation phonemes
// instead of "percent", "and", "plus", "at".
//
// Adapted from jlund/MisakiSwift, which guards that branch on the symbol not
// having a lexicon entry.

private func say(_ text: String) -> String {
  EnglishG2P(british: false).phonemize(text: text).0
}

@Test func symbolsWithALexiconEntryAreSpokenAsWords() {
  // Each symbol against the phonemes of the word it stands for, so the test
  // says what it means rather than pinning an opaque string.
  let cases: [(String, String)] = [
    ("50%",     say("50 percent")),
    ("cats & dogs", say("cats and dogs")),
    ("2 + 2",   say("2 plus 2")),
    ("me @ home", say("me at home")),
  ]
  for (input, expected) in cases {
    let out = say(input)
    #expect(!out.isEmpty, "'\(input)' phonemised to nothing")
    #expect(out == expected,
            "'\(input)' gave '\(out)', expected the same as its spelled-out form '\(expected)'")
  }
}

@Test func ordinaryPunctuationIsStillPunctuation() {
  // The guard must not rescue every symbol — punctuation that has NO lexicon
  // entry has to keep going through the punctuation path. Without this, a fix
  // that simply skipped the branch would pass the test above.
  for p in [",", ".", "?", "!", ";"] {
    let out = say("yes\(p)")
    #expect(out.contains(p) || out.hasSuffix(p),
            "'yes\(p)' lost its punctuation: '\(out)'")
  }
}
