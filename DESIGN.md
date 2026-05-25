# RTLER Design Notes

## Purpose

RTLER converts normal logical-order Arabic-script text into a visual-order, pre-shaped Unicode workaround for environments that do not support RTL layout or Arabic shaping, such as some design-tool text boxes.

The output is intentionally compatibility text: it is meant to look right when pasted into a non-RTL/non-shaping renderer. It is not meant to remain semantically clean, searchable, spellcheckable, or round-trippable.

## Important correction

The problem is not only “changing character representation.” Correct display normally requires two steps:

1. **Bidirectional ordering**: logical text is laid out visually right-to-left, while numbers and LTR runs keep their own order.
2. **Contextual shaping**: Arabic-script letters choose isolated, initial, medial, or final glyph forms based on neighboring join behavior.

For the MVP, RTLER will approximate this as text by emitting visual-order characters and Unicode Arabic Presentation Forms where possible.

## MVP scope

- Language/script scope: Arabic, Persian, and Urdu from day one.
- Rendering goal: readable connected text, not typographically faithful Nastaliq or calligraphic output.
- Directionality scope:
  - First: pure RTL lines.
  - Immediately after: mixed LTR/RTL content using the Unicode Bidirectional Algorithm.
- Interface:
  - Rust crate plus CLI.
  - CLI accepts stdin-to-stdout and an optional direct text argument.
  - Diagnostics/warnings go to stderr.
- Transform direction: one-way only, normal logical Unicode → visual compatibility Unicode.

## Text transformation rules

### Lines

Each explicit input line is transformed independently. RTLER will not predict target-app wrapping. Users should insert line breaks where they want stable visual lines.

### Shaping

The core shaper maps Arabic-script base letters to Unicode Arabic Presentation Forms according to joining context:

- isolated
- initial
- medial
- final

Lam-alef combinations are emitted as dedicated lam-alef presentation ligatures by default, including hamza/madda variants where applicable.

If a character cannot be mapped to a presentation form, RTLER preserves it and emits a diagnostic warning.

### Marks

Basic Arabic-script combining marks are supported from v1. Marks stay attached to their base character during reversing/shaping so they do not drift to the wrong visual letter.

Advanced Quranic mark fidelity and perfect mark positioning are outside the text MVP because placement depends on the target renderer and font.

### Numbers

Numeric runs preserve both:

- the original digit characters, e.g. `123`, `۱۲۳`, `١٢٣`
- the left-to-right digit order

RTLER does not auto-localize digits by language in v1.

### Punctuation and brackets

Paired brackets are mirrored using Unicode bidi mirroring behavior where appropriate, e.g. `(` ↔ `)`, `[` ↔ `]`, `{` ↔ `}`.

### Normalization

Input normalization is conservative:

- Existing Arabic Presentation Forms may be normalized back to their base letters before reshaping.
- Broad Unicode compatibility normalization, such as full NFKC over the whole string, is not applied by default.

## Dependencies

Rust implementation may use small, standard Unicode crates where helpful, especially for the mixed-content phase:

- `unicode-bidi` for Unicode Bidirectional Algorithm behavior.
- `unicode-segmentation` or equivalent logic for grapheme/mark-safe processing.

The Arabic presentation-form mapping and joining logic remain under RTLER’s control.

## Testing strategy

Primary correctness strategy:

- golden string fixtures for Arabic, Persian, and Urdu examples
- unit tests for joining forms, lam-alef, marks, digits, brackets, and line handling
- manual visual smoke tests by pasting sample output into Affinity-like non-RTL/non-shaping environments

Automated screenshot/render comparison is deferred.

## Deferred fallback

A typographically faithful fallback using HarfBuzz/rustybuzz is explicitly deferred until the text MVP is proven.

Important constraint: HarfBuzz produces positioned glyph IDs for a specific font. Those glyph IDs are usually not portable Unicode text. Therefore, the high-fidelity fallback will likely output vector outlines, such as SVG paths or PDF/vector data, rather than editable text.
