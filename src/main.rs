use std::io::{self, Read};

fn main() -> io::Result<()> {
    let input = if let Some(text) = std::env::args().nth(1) {
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
