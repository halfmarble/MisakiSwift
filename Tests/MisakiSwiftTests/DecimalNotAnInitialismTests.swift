import Testing
@testable import MisakiSwift

// A decimal whose dot-separated parts are all shorter than 3 characters used to
// be mistaken for an initialism ("3.5" splits like "U.S"), handed to getNNP,
// and come back as an EMPTY STRING — which transcribe accepted as a successful
// lookup, so the number never reached the number path and vanished silently.

private func say(_ text: String) -> String {
  EnglishG2P(british: false).phonemize(text: text).0
}

/// `pYnt` is "point". Its presence means the decimal was spoken as a number.
private let point = "pYnt"

@Test func shortDecimalsAreSpokenAndNotSwallowed() {
  for n in ["3.5", "0.5", "1.5", "12.5", "9.99", "12.55", "0.25"] {
    let out = say(n)
    #expect(!out.isEmpty, "\(n) phonemised to nothing at all")
    #expect(out.contains(point), "\(n) lost its decimal point: '\(out)'")
  }
}

@Test func aDecimalKeepsItsUnitWord() {
  // The shipped-corpus shape: a quantity followed by a unit. The unit alone
  // surviving is what the defect looked like from the outside — "3.5 miles"
  // was heard as "miles".
  let out = say("3.5 miles")
  #expect(out.contains(point), "no decimal point in '\(out)'")
  #expect(out.contains("mˈIlz"), "lost the unit in '\(out)'")
}

@Test func longerDecimalsStillWorkAsTheyAlwaysDid() {
  // These were never broken — their longest part is 3+ characters, so they
  // missed the initialism branch by luck. Asserted so a future change to the
  // guard cannot fix the short case by breaking the long one.
  for n in ["3.500", "100.1", "100.001", "1971.13"] {
    #expect(say(n).contains(point), "\(n) lost its decimal point")
  }
}

@Test func initialismsAreStillSpelledOut() {
  // THE REGRESSION RISK. The branch this fix narrows is the initialism path,
  // and it must still fire for its real subject: dotted letters.
  let out = say("The U.S.A. team")
  #expect(!out.isEmpty)
  // "U.S.A." spelled out contains the vowel-initial "ju" of the letter U;
  // asserting the whole string would break on any unrelated lexicon change.
  #expect(out.contains("j"), "U.S.A. no longer spelled out: '\(out)'")
}

@Test func theCheckCanFail() {
  // Control: a plain integer has no decimal point, so `point` must be absent.
  // Without this, every assertion above would pass if `point` appeared in
  // everything.
  #expect(!say("24").contains(point))
}
