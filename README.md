# MisakiSwift — halfmarble fork

> **What this is.** A fork of [mlalma/MisakiSwift](https://github.com/mlalma/MisakiSwift)
> carrying the pronunciation, packaging and performance fixes we needed to ship this package
> in an iOS app, kept here so others can use them. Upstream has been quiet since June 2026.
> Nothing here is novel — almost every change has an upstream issue or pull request, or comes
> from another public fork, and is credited where it does. The value is the set, applied
> together and tested as a set, which no single upstream PR gives you.
>
> **[FORK_CHANGES.md](FORK_CHANGES.md) lists every change, what it fixes, and which release it
> first shipped in.** In short: 21 through 29 lost their tens word; decimals were read through a
> `Double`, and short ones were dropped silently; a hyphen put a pause inside a compound word;
> `%`, `&` and `@` were dropped rather than spoken; "read" lost its past tense; the
> out-of-vocabulary fallback is memoized. Plus the three things it takes to ship on iOS — the
> resource bundle rename, the mlx-swift pin, and static linking.
>
> **What this is not.** Not a hostile fork, and not a claim that upstream is wrong. Everything
> here has been offered upstream as an issue or a PR, and if upstream merges them we would
> rather you used upstream.
>
> **Maintenance.** halfmarble maintains this fork and intends to keep fixing and extending it,
> because we ship it in production software — bugs here reach real users, so they get fixed
> here first. Issues and pull requests are welcome. We make no release-cadence or
> backwards-compatibility promise; pin a commit if you need one. Fork releases start at 2.0.0 —
> the inherited 1.0.x tags are upstream's code and carry none of this.
>
> Apache-2.0, same as upstream. Modified files carry a notice as section 4(b) requires.


A Swift port of the [Misaki](https://github.com/hexgrad/misaki) grapheme-to-phoneme (G2P) library for converting English text to phonetic representations suitable for text-to-speech (TTS) engines.

## Supported Platforms

- iOS 18.0+
- macOS 15.0+
- (Other Apple platforms may work as well)

## Installation

Add MisakiSwift to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/mlalma/MisakiSwift", from: "1.0.1")
]
```

## Basic Usage

```swift
import MisakiSwift

// Create G2P converter (british = false for American English)
let g2p = EnglishG2P(british: false)

// Convert text to phonemes
let (phonemes, tokens) = g2p.phonemize(text: "Hello world!")
print(phonemes) // "həlˈO wˈɜɹld!"
```

## Custom Phoneme Override

Use Markdown-like syntax to specify exact pronunciations in case you don't want to use fallback network:

```swift
let g2p = EnglishG2P(british: false)
let text = "[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models."
let (phonemes, _) = g2p.phonemize(text: text)
// "misˈɑki ɪz ɐ ʤˈitəpˈi ˈɛnʤən dəzˈInd fɔɹ kˈOkəɹO mˈɑdᵊlz."
```

## Overview

MisakiSwift is a high-quality English G2P conversion library that transforms written text into phonemes using both dictionary-based lookup and neural network fallback. It supports British and American English pronunciations and includes advanced features like stress pattern handling and custom phoneme overrides.

## Key Features

- **High Accuracy**: Combines extensive pronunciation dictionaries with neural network fallback for out-of-vocabulary words
- **Dual Dialect Support**: Supports both British and American English pronunciations
- **Advanced Text Processing**: Handles punctuation, numbers, acronyms, and complex formatting
- **Custom Phoneme Override**: Use Markdown-like syntax to specify exact pronunciations: `[word](/phonemes/)`
- **Stress Pattern Control**: Automatic stress assignment with manual override capabilities
- **Apple Ecosystem Integration**: Uses Apple's Natural Language framework instead of external dependencies like SpaCy

## Architecture

MisakiSwift consists of several key components:

- **`EnglishG2P`**: Main conversion pipeline that orchestrates tokenization, lexicon lookup, and neural network fallback
- **`Lexicon`**: Dictionary-based pronunciation lookup using gold and silver dictionaries
- **`EnglishFallbackNetwork`**: Transformer-based model (ported to run on MLX) for phoneme prediction for out-of-vocabulary words

## Key Differences from Python Misaki

1. **POS Tagging**: Uses Apple's `NaturalLanguage` framework instead of SpaCy for part-of-speech tagging
2. **Neural Network**: The BART-based fallback network is ported to run on [MLX](https://github.com/ml-explore/mlx-swift)
3. **Resource Management**: All model weights and dictionaries are bundled as resources within the Swift package

## Dependencies

- **[MLX](https://github.com/ml-explore/mlx-swift)**: Machine learning framework for the neural network component
- **NaturalLanguage**: Apple's built-in framework for text processing and POS tagging
- **MLXUtilsLibrary**: For `MToken`, used also in other parts of the ML stack

## Model Resources

The package includes pre-trained models and dictionaries:

- **BART Model Weights**: Neural network weights for phoneme prediction (US and GB variants)
- **Gold Dictionary**: High-confidence pronunciation mappings
- **Silver Dictionary**: Additional pronunciation mappings with slightly lower confidence

These resources are automatically bundled with the package and loaded at runtime.

## Running the Tests

Use `xcodebuild`, not `swift test`:

```sh
xcodebuild test -scheme MisakiSwift -destination 'platform=macOS'
```

`swift test` does not work on this package, and the way it fails is misleading: it reports

```
MLX error: Failed to load the default metallib. library not found ...
```

and then executes zero tests, which looks like a broken checkout or a bad dependency pin. It is
neither. SwiftPM on the command line cannot compile Metal shaders, so `default.metallib` is never
built — there will be no `.metallib` anywhere under `.build`. This is a documented mlx-swift
limitation rather than anything specific to MisakiSwift; see
[its README](https://github.com/ml-explore/mlx-swift#xcodebuild): *"SwiftPM (command line) cannot
build the Metal shaders so the ultimate build has to be done via Xcode."*

`xcodebuild` does compile them, and the suite then runs clean.
