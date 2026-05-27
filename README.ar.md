# RTLer

<p align="center">
  <img src="assets/logo/rtler-logo.svg" alt="شعار RTLer" width="112" height="112">
</p>

[![CI](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/mustafamohsen/rtler?include_prereleases&label=release)](https://github.com/mustafamohsen/rtler/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Rust](https://img.shields.io/badge/core-Rust-orange.svg)
![macOS beta](https://img.shields.io/badge/macOS-beta-111827.svg)
![Arabic script](https://img.shields.io/badge/script-Arabic%20%7C%20Urdu%20%7C%20Persian-38BDF8.svg)

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.ur.md">اُردو</a>
</p>

<div dir="rtl">

<p dir="rtl" align="right">
يحوّل <bdi>RTLer</bdi> النصوص العربية وما يشابهها من ترتيب <bdi>Unicode</bdi> المنطقي العادي إلى نص بصري مُشكّل مسبقًا، مناسب للتطبيقات التي لا تدعم اتجاه الكتابة من اليمين إلى اليسار أو تشكيل الحروف العربية بشكل صحيح.
</p>

<p dir="rtl" align="right">
يفيد <bdi>RTLer</bdi> في مسارات عمل التصميم والنشر عندما تظهر النصوص العربية أو الأردية أو الفارسية مفككة، أو معكوسة، أو غير صحيحة بعد لصقها في التطبيق الهدف.
</p>

## ماذا يفعل؟

- يشكّل الحروف العربية إلى صيغ Unicode presentation forms.
- يعيد ترتيب النص بصريًا ليظهر من اليمين إلى اليسار.
- يحافظ على المقاطع الشائعة المكتوبة من اليسار إلى اليمين، مثل الروابط، والبريد الإلكتروني، والأرقام، وأسماء الملفات.
- يدعم الحالات الأساسية للعربية والفارسية والأردية.
- يوفّر CLI ومكتبة Rust، بالإضافة إلى تطبيق macOS تجريبي.

## تنبيه مهم

مخرجات RTLer هي **نص بصري للتوافق**. الهدف منها أن تبدو صحيحة في التطبيقات ذات دعم RTL الضعيف، وليس أن تبقى Unicode نظيفًا من الناحية الدلالية.

احتفظ دائمًا بالنص الأصلي. النص المحوّل غير مناسب غالبًا للتحرير، أو البحث، أو التدقيق الإملائي، أو الوصول accessibility، أو المعالجة اللغوية.

## تطبيق macOS التجريبي

يوفّر إصدار macOS التجريبي زرًا عائمًا صغيرًا لتحويل النص المحدد في التطبيق الأمامي.

حمّل أحدث إصدار تجريبي من GitHub Releases، ثم فك الضغط عن `RTLer.app` وافتحه، وامنحه صلاحية Accessibility عند الطلب.

يعتمد التطبيق على أتمتة النسخ واللصق عبر الحافظة، لذلك قد يختلف السلوك حسب التطبيق الهدف. حفظ الحافظة حاليًا يركّز على النص العادي فقط.

## استخدام CLI

البناء من المصدر:

```bash
cargo build --release
```

أمثلة تشغيل:

```bash
cargo run -- "سلام"
echo "هذا نص عربي" | cargo run --quiet
cargo run -- --help
```

إذا كان مثبتًا باسم `rtler`:

```bash
rtler "سلام"
echo "هذا نص عربي" | rtler
```

تظهر التحذيرات في stderr، ويظهر النص المحوّل في stdout.

## استخدام مكتبة Rust

```rust
let result = rtler::transform("سلام");
assert_eq!(result.output, "ﻡﻼﺳ");
assert!(result.warnings.is_empty());
```

## التطوير

```bash
cargo fmt -- --check
cargo test
cargo clippy --all-targets --all-features -- -D warnings
```

فحوصات fixtures:

```bash
cargo run --quiet < fixtures/arabic-smoke-input.txt | diff -u fixtures/arabic-smoke-expected.txt -
cargo run --quiet < fixtures/mixed-arabic-smoke-input.txt | diff -u fixtures/mixed-arabic-smoke-expected.txt -
cargo run --quiet < fixtures/urdu-smoke-input.txt | diff -u fixtures/urdu-smoke-expected.txt -
cargo run --quiet < fixtures/persian-smoke-input.txt | diff -u fixtures/persian-smoke-expected.txt -
```

## حالة المشروع

RTLer في مرحلة beta. نواة التحويل مغطاة باختبارات آلية، وتطبيق macOS متاح كإصدار تجريبي للاختبار العملي في أدوات التصميم.

راجع `DESIGN.md` لملاحظات التصميم والقرارات التقنية.

## الإشعارات

<p dir="ltr" align="left">Developed by Mustafa Mohsen.</p>

<p dir="ltr" align="left">Copyright (c) 2026 Mustafa Mohsen. Licensed under the <a href="LICENSE">MIT License</a>.</p>

</div>
