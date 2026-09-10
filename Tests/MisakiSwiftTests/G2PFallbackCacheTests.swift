import Testing
@testable import MisakiSwift

// THE MEMO FOR THE OOV BART FALLBACK.
//
// A miss runs BARTModel.generate, which loops to maxLength 50 and calls
// `.item()` on each step's argmax — up to fifty GPU->CPU synchronisations, on
// the same MLX worker the TTS decoder uses. A word that recurs later in a drive
// should not pay that twice.
//
// Ported from @ahh1539's fork (1.0.12). The two struct-level tests below are
// theirs in substance; the two integration tests are not, and they exist
// because the struct tests pass whether or not anything ever CONSULTS the
// cache. A memo that is never wired in is exactly the failure that would
// otherwise ship green.

@Test func fallbackCacheCountsLookupsHitsAndResetsOnConsume() {
  var cache = G2PFallbackCache(capacity: 8)

  #expect(cache.lookup("Junco") == nil)
  cache.store("Junco", phoneme: "ʤˈʌŋkoʊ", rating: 1)
  #expect(cache.lookup("Junco")?.phoneme == "ʤˈʌŋkoʊ")
  #expect(cache.lookup("Junco")?.rating == 1)

  let stats = cache.consumeStats()
  #expect(stats.lookups == 3)
  #expect(stats.hits == 2)
  #expect(stats.misses == 1)
  #expect(cache.consumeStats() == .zero)
}

@Test func fallbackCacheEvictsOldestKeyAtCapacity() {
  var cache = G2PFallbackCache(capacity: 2)
  cache.store("one", phoneme: "a", rating: 1)
  cache.store("two", phoneme: "b", rating: 1)
  cache.store("three", phoneme: "c", rating: 1)

  _ = cache.consumeStats()
  #expect(cache.lookup("one") == nil)
  #expect(cache.lookup("two")?.phoneme == "b")
  #expect(cache.lookup("three")?.phoneme == "c")
}

// MARK: - the half the struct tests cannot reach

/// THE WIRING, NOT THE CONTAINER. Phonemizes an invented word twice and asserts
/// the second pass is answered from the memo.
///
/// It also asserts the two passes return the SAME phonemes, which is the
/// property that makes memoizing legitimate at all: `generate` selects with
/// `argMax` and never samples, so a cache cannot change what is spoken. If that
/// ever becomes sampled, this assertion is what should start failing.
@Test func theFallbackNetworkActuallyConsultsTheMemo() {
  let g2p = EnglishG2P(british: false)

  let (first, _) = g2p.phonemize(text: "Zorbulax")
  let firstStats = g2p.consumeFallbackStats()

  // Guard the premise rather than assuming it: if this word never reached the
  // fallback, the rest of the test would be measuring nothing.
  #expect(firstStats.lookups > 0,
          "the invented word never reached the BART fallback, so this test proves nothing")
  #expect(firstStats.hits == 0, "first sight of a word cannot be a cache hit")

  let (second, _) = g2p.phonemize(text: "Zorbulax")
  let secondStats = g2p.consumeFallbackStats()

  #expect(secondStats.hits > 0, "the second pass re-decoded a word the memo already held")
  #expect(first == second, "memoized phonemes differ from the freshly decoded ones")
}

/// THE CONTROL. The test above would also pass for a memo that reported a hit
/// for everything, so this pins the other side: an unseen word must miss.
@Test func aWordNotSeenBeforeIsAMissNotAHit() {
  let g2p = EnglishG2P(british: false)

  _ = g2p.phonemize(text: "Zorbulax")
  _ = g2p.consumeFallbackStats()

  _ = g2p.phonemize(text: "Quibbleforth")
  let stats = g2p.consumeFallbackStats()

  #expect(stats.lookups > 0, "the second invented word never reached the fallback")
  #expect(stats.hits == 0, "a word never seen before was reported as a cache hit")
}
