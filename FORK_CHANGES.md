# What this fork changes

Everything [halfmarble/MisakiSwift](https://github.com/halfmarble/MisakiSwift) carries on
top of [mlalma/MisakiSwift](https://github.com/mlalma/MisakiSwift), why it is here, and
which release it first shipped in. The README says what the fork *is*; this file tracks
what is *in* it, and it is updated in the same commit as the change it describes.

Nothing here is novel. Almost every entry has an upstream issue or pull request, or comes
from another public fork, and is credited where it does. The value is the set, applied
together and tested as a set — which no single upstream PR gives you.

**Fork releases start at 2.0.0.** The inherited `1.0.x` tags are upstream's code and carry
none of this. Pin an exact version if you need one: there is no compatibility promise.

## Pronunciation fixes

These change what the library says out loud. Each was found by synthesising with Kokoro and
transcribing the audio back with an on-device recogniser, so the evidence is what a listener
hears rather than what the phoneme string looks like.

### 21 through 29 lost their tens word — since 2.0.0

`midNumWords` had no entry for 20, and `toCardinal` falls back to an empty string on a miss,
so `convert(24)` returned `"-four"` and was spoken as "four". It propagated two ways:
`toCardinal` recurses, so 124 became "one hundred and -four"; and `Lexicon` routes any
four-digit token through `toYear`, so 2024 became "twenty -four".

Measured over 1 to 3000: **1,091 of 3,000 numbers were spoken wrongly** before the fix. Every
other two-digit value tested was already correct, because 30 through 90 are present. Not a bug
in the Python Misaki this is ported from, which delegates to `num2words`.

Upstream: issue [#16](https://github.com/mlalma/MisakiSwift/issues/16), fixed in
[#18](https://github.com/mlalma/MisakiSwift/pull/18).

### A hyphen joining a compound put a pause inside the word — since 2.0.0

`—` is a real token in Kokoro's vocabulary, so emitting it for every token tagged `Dash` broke
compounds in half: "self-compassion" was spoken in two pieces and transcribed back as "Salva
compassion". A standalone dash used as punctuation should still pause, and still does.

The original fix is YokiiDesu's, from
[YokiiDesu/MisakiSwift](https://github.com/YokiiDesu/MisakiSwift) (Apache-2.0). This differs in
one respect: **it emits a space rather than an empty string.** An empty string removes the pause
and then concatenates the two halves' phonemes with no boundary, which fixes the pause and
invents a new word:

| written | empty string | space |
|---|---|---|
| senior-most | "Say your most" | "Senior most" |
| four-limbed | "For lamb" | "For limbed" |

Over 20 hyphenated compounds: 14/20 transcribed back exactly with the empty string, 15/20 with
a space, and the remaining differences are the recogniser rather than the voice.

### A written decimal was read through a `Double` — since 2.1.0

`Lexicon.getNumber` routed decimal text through `Double` before converting.
`Double("1971.13")` is a binary approximation holding 1971.130000000000512, and
`Decimal(_: Double)` preserves it, so every one of those fractional digits was read aloud.
`Decimal(string:)` is exact for decimal text, and `extend_num` in the same file already parsed
that way, so the two sites now agree. Written zeros are unaffected: 100.001 still reads as one
hundred point zero zero one.

### A short decimal was silently dropped — since 2.1.1

`getSpecialCase` treats any dotted word whose parts are all shorter than three characters as an
initialism and hands it to `getNNP` to be spelled out. It never checked that the parts were
letters, so "3.5" split to `["3","5"]` and looked exactly like "U.S". `getNNP` then found no
letters and returned an **empty string rather than nil** — and empty is not nil, so the lookup
counted as a success and the number path was never reached. The number vanished with nothing
logged:

| written | spoken |
|---|---|
| 3.5 miles | "miles" |
| 0.5 mg | "MG" |
| 12.5 percent | "percent" |

The three-character cutoff is why the pattern looked arbitrary: "3.500" and "100.1" have a
three-character part, missed the branch and were correct, while "3.5" and "9.99" were silent.
Same value, different text.

### A token with both letters and digits lost its digits — since 2.2.0

The guard above asked whether a token contains a **letter**. It should ask whether it contains a
**digit**. Both keep "3.5" out and let "U.S.A" in, so no pure case distinguishes them — only a
token carrying both: `v1.2` was spoken as "vee", the digits dropped exactly as a decimal used to
be. A digit anywhere means this is not an initialism. Adapted from
[jlund/MisakiSwift](https://github.com/jlund/MisakiSwift) (Apache-2.0).

Two related tokens are deliberately **not** covered: "Mk2.5" and "iOS16.4" never reach this
branch, they go through the fallback network, so asserting them here would make the test depend
on untouched code.

### `%`, `&` and `@` were dropped rather than spoken — since 2.2.0

`Lexicon.symbolSet` maps these to "percent", "and" and "at", but the tagger marks them as
punctuation and the punctuation branch claimed them before the lexicon was consulted. The result
was a hole rather than a mispronunciation: "50%" became "fifty", "cats & dogs" became "cats
dogs". `+` escaped because the tagger does not consistently call it punctuation, which is why
this looked occasional rather than systematic. The branch now stands down for any symbol that
has a lexicon entry. Adapted from [jlund/MisakiSwift](https://github.com/jlund/MisakiSwift)
(Apache-2.0).

### "read", "reread" and "wound" lost their tense — since 2.2.0

These are spelled the same in present and past and pronounced differently. The gold lexicon keys
those readings on fine-grained Penn tags, which upstream Misaki gets from spaCy's contextual
tagger; Apple's `NLTagger` emits only a coarse `.verb`, so every reading collapsed to the
present and "I have read it" was spoken with "reed".

A pre-pass re-derives the past-versus-present signal from the local token neighbourhood — nearest
governing auxiliary or modal, skipping adverbs, then an explicit past-time cue — and pins the
phonemes through a new `forcedPennTag` parameter that reaches the VBD/VBN entries nothing else
can address. The parameter defaults to nil the whole way down, so every existing caller is
unchanged. Adapted from
[KristopherGBaker/MisakiSwift](https://github.com/KristopherGBaker/MisakiSwift) (Apache-2.0).

## Performance

### The out-of-vocabulary fallback is memoized — since 2.2.1

A word outside the lexicon is not a dictionary miss, it is a BART decode: `BARTModel.generate`
loops to `maxLength` 50 and calls `.item(Int32.self)` on each step's argmax, so **one miss costs
up to fifty GPU-to-CPU synchronisations** on the same MLX worker the TTS decoder uses. A proper
noun that recurs later paid that again for an answer already computed.

`EnglishFallbackNetwork` now consults a bounded word-to-phoneme memo before decoding, and
`EnglishG2P.consumeFallbackStats()` reports lookups and hits since the previous read.

**Memoizing is safe here, which is not true of every generator.** `generate` selects with
`argMax()` and never samples, so it is deterministic and the cache cannot change what is spoken,
only how often it is computed. If that ever becomes sampled the cache has to go, and the test
asserting both passes return identical phonemes is what should start failing. The key is
`word.text`, and that covers the function's entire input: `callAsFunction` reads nothing else off
the token. Capacity is a 4096-entry insertion-order cap rather than an LRU — a session's
out-of-vocabulary set is small and repetitive, so having a bound matters more than the eviction
policy. Ported from ahh1539's fork (1.0.12).

## Packaging and build

All three are what it takes to ship this package in an iOS app, and all three are in **2.0.0**.

- **iOS codesign rejected the resource bundle.** SwiftPM names the bundle's top-level folder
  after the `.copy()` path, and when that folder is literally `Resources` codesign fails with
  "bundle format unrecognized" — the app cannot be signed or installed. Renamed to `MisakiData/`,
  with the four subdirectory lookups and the manifest moved to match. Same ground as
  [#20](https://github.com/mlalma/MisakiSwift/pull/20).
- **mlx-swift pinned to 0.31.6.** 0.30.2 does not link against the iOS 26 simulator SDK —
  undefined `_MTLTensorDomain` and `_MTLIOErrorDomain`. Same ground as
  [#19](https://github.com/mlalma/MisakiSwift/pull/19) and
  [#13](https://github.com/mlalma/MisakiSwift/pull/13).
- **The library product links statically.** The explicit `type: .dynamic` embedded MLX and MLXNN
  as frameworks, so an app that also links a static MLX consumer ended up with two MLX runtimes
  in one process: duplicate Objective-C class warnings at launch, and crashes that are hard to
  attribute.

Consuming this package: mlx-swift 0.31.5 and later ship a Linux-only `CudaBuild` plugin, so
command-line builds need `-skipPackagePluginValidation`, and Xcode asks once to trust it.

## Tests and CI

The suite runs on every push and pull request — `xcodebuild test` on a `macos-26` Apple Silicon
runner, added in 2.1.0. Three things it needs are not obvious, and each was found by a failing
run rather than guessed:

- **`xcodebuild`, not `swift test`.** SwiftPM on the command line cannot compile the Metal
  shaders mlx-swift needs, so tests abort on a missing `default.metallib` **while the process
  still exits 0** — a green run that executed nothing. The README documents this, because it
  reads as a broken checkout rather than a tooling limitation.
- **`macos-26`, not `macos-15`.** The `macos-15` image still defaults to Xcode 16.4 and Swift
  6.1, below this package's `swift-tools-version` 6.2, and fails at dependency resolution.
- **`-skipPackagePluginValidation`**, for the `CudaBuild` plugin a fresh runner cannot approve.

Every behavioural change above ships with a test, and several ship with a **control** — an
assertion that fails if the test's own premise stops holding, so a fix cannot pass vacuously.

## Release index

| version | what it added |
|---|---|
| 2.0.0 | iOS packaging (bundle rename, mlx-swift pin, static linking); the missing tens word; the hyphen pause |
| 2.1.0 | Decimals parsed as base-10 text; CI |
| 2.1.1 | Short decimals no longer silently dropped |
| 2.2.0 | `%`, `&`, `@` spoken; digits survive in mixed tokens; verb tense recovered |
| 2.2.1 | Out-of-vocabulary fallback memoized, with lookup and hit stats |

## Licence

Apache-2.0, same as upstream. Modified files carry a notice as section 4(b) requires, and the
forks credited above are Apache-2.0 too.
