# RTLer

[![CI](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/mustafamohsen/rtler?include_prereleases&label=release)](https://github.com/mustafamohsen/rtler/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Rust](https://img.shields.io/badge/core-Rust-orange.svg)
![macOS beta](https://img.shields.io/badge/macOS-beta-111827.svg)
![Arabic script](https://img.shields.io/badge/script-Arabic%20%7C%20Urdu%20%7C%20Persian-38BDF8.svg)

RTLer عربی رسم الخط کے متن کو عام منطقی Unicode ترتیب سے بصری ترتیب اور پہلے سے بنائی گئی compatibility شکلوں میں تبدیل کرتا ہے، تاکہ وہ ایپس میں درست نظر آئے جو دائیں سے بائیں متن یا عربی حروف کی shaping کو صحیح طور پر support نہیں کرتیں۔

یہ ڈیزائن اور پبلشنگ workflows کے لیے مفید ہے، خاص طور پر جب عربی، اردو، یا فارسی متن target app میں paste کرنے کے بعد ٹوٹا ہوا، الٹا، یا غلط دکھائی دے۔

[English](README.md) · [العربية](README.ar.md)

## یہ کیا کرتا ہے؟

- عربی رسم الخط کے حروف کو Unicode presentation forms میں shape کرتا ہے۔
- متن کو بصری طور پر دائیں سے بائیں display کے لیے reorder کرتا ہے۔
- عام left-to-right runs، جیسے URLs، emails، numbers، اور filenames کو محفوظ رکھتا ہے۔
- عربی، فارسی، اور اردو کے بنیادی text cases کو support کرتا ہے۔
- Rust CLI/library کے ساتھ ایک تجرباتی macOS app بھی فراہم کرتا ہے۔

## اہم نوٹ

RTLer کا output **visual compatibility text** ہے۔ اس کا مقصد کمزور RTL support والی apps میں متن کو درست دکھانا ہے، نہ کہ semantically clean Unicode برقرار رکھنا۔

اپنا اصل source text ہمیشہ محفوظ رکھیں۔ transformed output editing، searching، spellchecking، accessibility، یا linguistic processing کے لیے مثالی نہیں ہے۔

## macOS beta app

macOS beta ایک چھوٹا floating button فراہم کرتا ہے جو سامنے والی app میں selected text کو transform کرتا ہے۔

GitHub Releases سے تازہ ترین beta download کریں، `RTLer.app` unzip کر کے open کریں، اور prompt آنے پر Accessibility permission دیں۔

یہ app clipboard-mediated copy/paste automation استعمال کرتی ہے، اس لیے behavior target application کے حساب سے مختلف ہو سکتا ہے۔ Clipboard preservation فی الحال plain text تک محدود ہے۔

## CLI استعمال

source سے build کریں:

```bash
cargo build --release
```

examples:

```bash
cargo run -- "سلام"
echo "هذا نص عربي" | cargo run --quiet
cargo run -- --help
```

اگر `rtler` کے طور پر installed ہو:

```bash
rtler "سلام"
echo "هذا نص عربي" | rtler
```

Warnings stderr پر آتی ہیں۔ transformed text stdout پر آتا ہے۔

## Rust library استعمال

```rust
let result = rtler::transform("سلام");
assert_eq!(result.output, "ﻡﻼﺳ");
assert!(result.warnings.is_empty());
```

## Development

```bash
cargo fmt -- --check
cargo test
cargo clippy --all-targets --all-features -- -D warnings
```

Fixture checks:

```bash
cargo run --quiet < fixtures/arabic-smoke-input.txt | diff -u fixtures/arabic-smoke-expected.txt -
cargo run --quiet < fixtures/mixed-arabic-smoke-input.txt | diff -u fixtures/mixed-arabic-smoke-expected.txt -
cargo run --quiet < fixtures/urdu-smoke-input.txt | diff -u fixtures/urdu-smoke-expected.txt -
cargo run --quiet < fixtures/persian-smoke-input.txt | diff -u fixtures/persian-smoke-expected.txt -
```

## Project status

RTLer beta مرحلے میں ہے۔ core transform automated tests سے covered ہے، اور macOS app design tools میں real-world testing کے لیے experimental beta کے طور پر دستیاب ہے۔

implementation notes اور tradeoffs کے لیے `DESIGN.md` دیکھیں۔
