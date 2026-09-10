import Testing
@testable import MisakiSwift

// The initialism branch recognises "U.S.A" by every dot-separated part being
// shorter than 3 characters, then spells the letters out. A guard keeps
// decimals away from it — "3.5" splits like "U.S" and is not an initialism.
//
// WHICH guard matters only for tokens carrying BOTH letters and digits, since
// every pure case agrees. "contains a letter" let "v1.2" through to the
// spell-out path, which found the letters, ignored the digits, and returned
// "vˈi " — the number dropped, exactly as a decimal used to. "no digit" keeps
// it out and the digits survive: "vˈi wˈʌn tˈu".
//
// THIS ASSERTS THE DIGITS SURVIVE, NOT THAT A "POINT" IS SPOKEN. Reading
// "v1.2" as "vee one two" is a reasonable rendering of a version number, and
// demanding "vee one point two" would be asserting a behaviour this guard was
// never going to produce.

private func say(_ text: String) -> String {
  EnglishG2P(british: false).phonemize(text: text).0
}

@Test func aDottedTokenWithLettersAndDigitsKeepsItsDigits() {
  let out = say("v1.2")
  #expect(!out.isEmpty, "'v1.2' phonemised to nothing")
  // Against the phonemes of the digits themselves, so the test states its
  // intent rather than pinning an opaque string.
  #expect(out.contains(say("1")), "'v1.2' lost the 1: '\(out)'")
  #expect(out.contains(say("2")), "'v1.2' lost the 2: '\(out)'")
  #expect(out != say("v"), "'v1.2' collapsed to just the letter: '\(out)'")
}

@Test func realInitialismsAreStillSpelledOut() {
  // The other side of the guard. A change that fixed the mixed case by
  // disabling the branch entirely would break these.
  for t in ["U.S.A", "M.R.C.S", "B.B.C"] {
    let out = say(t)
    #expect(!out.isEmpty, "'\(t)' phonemised to nothing")
    #expect(!out.contains("pYnt"), "'\(t)' should not contain a decimal point: '\(out)'")
  }
}

@Test func decimalsAreStillNotInitialisms() {
  // The guard this replaced existed for these; asserted here too so the two
  // predicates cannot be confused by a future edit.
  for n in ["3.5", "0.5", "12.55"] {
    #expect(say(n).contains("pYnt"), "'\(n)' lost its decimal point")
  }
}
