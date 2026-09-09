import Foundation
import Testing
@testable import MisakiSwift

/// `midNumWords` had no entry for 20, and `toCardinal` falls back to an empty
/// string when the tens lookup misses — so every 21-29 lost its tens word and
/// only the units digit survived. It propagates two ways: `toCardinal` recurses
/// for composites, and `Lexicon` routes any 4-digit token through `toYear`,
/// which builds from `toCardinal`.
@Test func cardinalsInTheTwentiesKeepTheTensWord() {
  let n = EnglishNum2Word()
  #expect(n.convert(Decimal(21)) == "twenty-one")
  #expect(n.convert(Decimal(24)) == "twenty-four")
  #expect(n.convert(Decimal(29)) == "twenty-nine")
}

@Test func otherTensAreUnaffected() {
  let n = EnglishNum2Word()
  #expect(n.convert(Decimal(20)) == "twenty")
  #expect(n.convert(Decimal(30)) == "thirty")
  #expect(n.convert(Decimal(45)) == "forty-five")
  #expect(n.convert(Decimal(99)) == "ninety-nine")
}

@Test func compositesBuiltOnTheTwentiesAreCorrect() {
  let n = EnglishNum2Word()
  #expect(n.convert(Decimal(124)).contains("twenty-four"))
  #expect(n.convert(Decimal(224)).contains("twenty-four"))
}

@Test func yearsBuiltOnTheTwentiesAreCorrect() {
  let n = EnglishNum2Word()
  #expect(n.convert(Decimal(2024), to: .year) == "twenty twenty-four")
  #expect(n.convert(Decimal(1971), to: .year) == "nineteen seventy-one")
}
