// Copyright (c) 2026 Mustafa Mohsen
// SPDX-License-Identifier: MIT

use std::io::{self, Read};

fn main() -> io::Result<()> {
    let arg = std::env::args().nth(1);

    if matches!(arg.as_deref(), Some("--help") | Some("-h")) {
        println!(
            "Usage: rtler [TEXT]\n\nTransform Arabic-script text for non-RTL/non-shaping environments.\n\nIf TEXT is omitted, rtler reads stdin and writes transformed text to stdout.\n\nDeveloped by Mustafa Mohsen.\nLicensed under the MIT License."
        );
        return Ok(());
    }

    if matches!(arg.as_deref(), Some("--version") | Some("-V")) {
        println!("rtler {}", env!("CARGO_PKG_VERSION"));
        return Ok(());
    }

    let input = if let Some(text) = arg {
        text
    } else {
        let mut input = String::new();
        io::stdin().read_to_string(&mut input)?;
        input
    };

    let result = rtler::transform(&input);

    for warning in result.warnings {
        eprintln!("warning: {}: {}", warning.character, warning.message);
    }

    if std::env::args().nth(1).is_some() {
        println!("{}", result.output);
    } else {
        print!("{}", result.output);
    }

    Ok(())
}
