import Foundation

/// Counts of out-of-lexicon BART fallback lookups since the last consume.
/// `hits` are words that reused a memoized phoneme and skipped generation.
public struct G2PFallbackStats: Sendable, Equatable {
  public var lookups: Int
  public var hits: Int
  public var misses: Int { lookups - hits }

  public static let zero = G2PFallbackStats(lookups: 0, hits: 0)

  public init(lookups: Int, hits: Int) {
    self.lookups = lookups
    self.hits = hits
  }
}

/// A bounded `word -> phoneme` memo for the OOV BART fallback.
///
/// # WHY THIS IS WORTH A CACHE
///
/// A miss is not a dictionary lookup, it is a **BART decode**: `BARTModel
/// .generate` runs `for i in 0..<maxLength` with `maxLength` defaulting to 50,
/// and calls `.item(Int32.self)` on the argmax INSIDE that loop. Each `.item()`
/// is a GPU->CPU synchronisation, so one miss costs up to **fifty host syncs**
/// — on the same MLX worker the TTS decoder uses. A proper noun that recurs in
/// later chunks would pay that again for an answer already computed.
///
/// # WHY MEMOIZING IS SAFE HERE, WHICH IS NOT TRUE OF EVERY GENERATOR
///
/// `generate` selects with `scaledLogits.argMax()` and never samples, so it is
/// deterministic: the same word yields the same phonemes every time. Caching
/// therefore cannot change what is spoken, only how often it is computed.
/// **If that ever becomes sampled, this cache changes behaviour and must go.**
///
/// The key is `word.text` and that is exactly right rather than merely
/// convenient: `callAsFunction` reads NOTHING ELSE off the `MToken` — not the
/// tag, not the whitespace — so the key covers the function's entire input.
///
/// Capacity is an insertion-order cap, not an LRU. A voice session's OOV set is
/// small and repetitive, so the eviction policy matters far less than having a
/// bound at all; the bound exists so a long drive cannot grow this without
/// limit.
///
/// Ported from @ahh1539's MisakiSwift fork (1.0.12). Their commit carried no
/// manifest change, so unlike the rest of that fork it brings no MLX repoint
/// with it.
struct G2PFallbackCache: Sendable {
  struct Entry: Sendable, Equatable {
    let phoneme: String
    let rating: Int
  }

  private var storage: [String: Entry] = [:]
  private var insertionOrder: [String] = []
  private let capacity: Int
  private(set) var lookups = 0
  private(set) var hits = 0

  init(capacity: Int = 4096) {
    self.capacity = max(1, capacity)
  }

  mutating func lookup(_ key: String) -> Entry? {
    lookups += 1
    if let entry = storage[key] {
      hits += 1
      return entry
    }
    return nil
  }

  mutating func store(_ key: String, phoneme: String, rating: Int) {
    if storage[key] == nil {
      if storage.count >= capacity {
        let oldest = insertionOrder.removeFirst()
        storage.removeValue(forKey: oldest)
      }
      insertionOrder.append(key)
    }
    storage[key] = Entry(phoneme: phoneme, rating: rating)
  }

  /// Reports the counts since the previous call and resets them, so a caller
  /// reading once per `phonemize` sees that call's figures rather than a
  /// running total.
  mutating func consumeStats() -> G2PFallbackStats {
    let stats = G2PFallbackStats(lookups: lookups, hits: hits)
    lookups = 0
    hits = 0
    return stats
  }
}
