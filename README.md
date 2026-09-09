# MisakiSwift — halfmarble fork

> **What this is.** A fork of [mlalma/MisakiSwift](https://github.com/mlalma/MisakiSwift)
> carrying three fixes we needed to ship an iOS app, kept here so others can use them.
> Upstream has been quiet since June 2026 and has nine open pull requests; several of
> them fix the same things independently. Nothing here is novel — it is these fixes
> applied together and tested as a set, which no single upstream PR gives you.
>
> - **Numbers 21-29 lost their tens word.** `convert(24)` returned `"-four"` and was
>   spoken as "four". It reached composites (`124` -> "one hundred and -four") and years
>   (`2024` -> "twenty -four"). One missing table row. Also filed upstream as
>   [#16](https://github.com/mlalma/MisakiSwift/issues/16) and fixed in
>   [#18](https://github.com/mlalma/MisakiSwift/pull/18).
> - **iOS codesign rejected the resource bundle** whose top folder was named
>   `Resources`. Renamed to `MisakiData/`. Same ground as
>   [#20](https://github.com/mlalma/MisakiSwift/pull/20).
> - **mlx-swift pinned to 0.31.6** (0.30.2 will not link against the iOS 26 simulator
>   SDK) and the library product left to link statically, so an app does not end up with
>   two MLX runtimes. Same ground as
>   [#19](https://github.com/mlalma/MisakiSwift/pull/19) and
>   [#13](https://github.com/mlalma/MisakiSwift/pull/13).
>
> **What this is not.** Not a maintained project and not a replacement for upstream. We
> are not taking over the library; we will not be triaging issues or adding features. If
> upstream merges these, use upstream. Pin a commit if you depend on this.
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
