# LOGO Text Transliteration

This document defines a proposed LOGO text primitive for applying ICU String Transform rules to editor text.

## Purpose

The feature gives LOGO scripts a portable way to transform human-language text:

- Transliteration, such as Latin text to Hiragana.
- Width conversion, such as fullwidth to halfwidth.
- Script conversion, romanization, or normalization supported by ICU.

This is meant for writing and editing workflows, not for file format conversion or general data type conversion.

## Primitive Name

The primary primitive should be:

```logo
TRANSLIT transform-id text
```

`TRANSLIT` is intentionally narrower than `CONVERT` and less generic than `TRANSFORM`. It communicates that the operation is text/script oriented, while still being short enough to feel natural in LOGO.

`TRANSFORM` may be accepted as an alias if useful, but `TRANSLIT` should be the documented name.

## Examples

```logo
TRANSLIT "Any-Hiragana "Sakura
```

Returns transformed text using the ICU transform named `Any-Hiragana`.

```logo
TRANSLIT "Fullwidth-Halfwidth "ＡＢＣ１２３
```

Returns halfwidth text when the platform ICU data supports that transform.

```logo
TYPE TRANSLIT "Latin-ASCII "Café
```

Inserts the transformed result into the current buffer.

## Semantics

`TRANSLIT` is a reporter. It does not modify the buffer by itself.

The first argument is an ICU transform identifier. The second argument is the input text. The primitive returns the transformed string.

This keeps composition simple:

```logo
MAKE "kana TRANSLIT "Any-Hiragana "Sakura
TYPE :kana
```

Editing actions should be built by combining `TRANSLIT` with existing editor primitives such as `TYPE`, selection reporters, or future text-selection primitives.

## Argument Rules

The transform identifier is parsed as a LOGO word or string.

The input text is parsed as a LOGO value. Quoted words, variables, expression results, and procedure outputs should all be accepted where the expression evaluator already accepts them.

Examples:

```logo
TRANSLIT "Any-Hiragana "Sakura
TRANSLIT "Any-Hiragana :word
TRANSLIT :rule :word
```

For text containing spaces, use the existing LOGO list/string conventions supported by the evaluator. If future LOGO string handling grows richer, `TRANSLIT` should follow that model instead of adding special parsing rules.

## Platform Behavior

The public behavior should be the same on macOS and Linux:

```swift
TextTransformer.apply("Any-Hiragana", to: "Sakura")
```

The implementation may differ by platform:

- macOS can use Foundation/CoreFoundation ICU-backed string transforms.
- Linux should use ICU C APIs directly, such as `utrans_open`, `utrans_transUChars`, and `utrans_close`.

Linux builds may require system ICU development libraries, for example `libicu-dev` on Debian/Ubuntu.

## Errors

Invalid transform identifiers should fail clearly.

Recommended LOGO behavior:

- As a reporter: throw/evaluate as a LOGO error with a message such as `Unknown text transform: Any-Example`.
- As part of a top-level command: stop the current LOGO script and report the error through the normal status/error path.

The primitive should not silently return the original text when the transform is unavailable. Silent fallback would make cross-platform editing scripts difficult to trust.

## Determinism

ICU transform availability and exact output may vary by ICU version and platform data.

The editor should document that `TRANSLIT` depends on the host ICU data. Tests should cover a small baseline set of transforms that are expected to be available on both supported platforms.

Suggested baseline transforms:

- `Fullwidth-Halfwidth`
- `Latin-ASCII`
- `Any-Latin`

Transforms such as `Any-Hiragana` are valuable user-facing examples, but should be treated carefully in portability tests because romanization behavior may vary.

## Non-Goals

`TRANSLIT` is not a translation feature. It does not translate semantic meaning between languages.

It is not a general conversion primitive for files, numbers, encodings, or structured data.

It should not perform editor mutations directly. Buffer-editing behavior belongs in composition with existing or future editor primitives.
