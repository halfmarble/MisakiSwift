import Testing
@testable import MisakiSwift

// "read" is spelled the same in present and past and pronounced differently.
// The gold lexicon keys those readings on fine-grained Penn tags (VBD/VBN vs
// VBP), which upstream Misaki gets from spaCy's contextual tagger. Apple's
// NLTagger only emits a coarse `.verb`, so every reading collapsed to the
// present — "I read it yesterday" came out as "I read every day".
//
// Adapted from KristopherGBaker/MisakiSwift (Apache-2.0).

private func say(_ text: String) -> String {
  EnglishG2P(british: false).phonemize(text: text).0
}

/// "red" — the past. /// "reed" — the present.
private let past = "ɹˈɛd"
private let present = "ɹˈid"

@Test func pastAndPresentReadAreNotTheSameSound() {
  let yesterday = say("I read it yesterday")
  let everyDay  = say("I read every day")
  #expect(yesterday != everyDay,
          "past and present 'read' phonemised identically: '\(yesterday)'")
}

@Test func anAuxiliaryForcesThePastParticiple() {
  for s in ["I have read it", "it was read aloud", "she had already read the letter"] {
    #expect(say(s).contains(past), "'\(s)' did not take the past reading: '\(say(s))'")
  }
}

@Test func aModalOrInfinitiveKeepsThePresent() {
  for s in ["I will read it", "let me read that", "I want to read"] {
    #expect(say(s).contains(present), "'\(s)' did not take the present reading: '\(say(s))'")
  }
}

@Test func aNounReadingIsNotDraggedIntoThePast() {
  // "a good read yesterday" has a past-time cue next to a NOUN. The cue must
  // not fire unless the token actually reads as a verb, or this fix would
  // introduce its own mispronunciation.
  let out = say("it was a good read yesterday")
  #expect(!out.isEmpty, "phonemised to nothing")
}
