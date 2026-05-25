#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransformResult {
    pub output: String,
    pub warnings: Vec<Warning>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Warning {
    pub character: char,
    pub message: String,
}

pub fn transform(input: &str) -> TransformResult {
    let output = input
        .split('\n')
        .map(transform_line)
        .collect::<Vec<_>>()
        .join("\n");

    TransformResult {
        output,
        warnings: Vec::new(),
    }
}

fn transform_line(input: &str) -> String {
    let shaped = shape(input);
    shaped.into_iter().rev().collect::<String>()
}

fn shape(input: &str) -> Vec<String> {
    let letters = collect_letters(input);

    letters
        .iter()
        .enumerate()
        .map(|(index, letter)| {
            let mut cluster = String::new();
            if let Some(literal) = &letter.literal {
                return literal.clone();
            }

            let shaped = if let Some(ligature) = letter.lam_alef {
                let previous_joins_to_current = index > 0
                    && letters[index - 1].can_connect_to_left()
                    && letter.can_connect_to_right();
                if previous_joins_to_current {
                    ligature.final_form
                } else {
                    ligature.isolated
                }
            } else if let Some(forms) = letter.forms {
                let previous_joins_to_current = index > 0
                    && letters[index - 1].can_connect_to_left()
                    && letter.can_connect_to_right();
                let current_joins_to_next = index + 1 < letters.len()
                    && letter.can_connect_to_left()
                    && letters[index + 1].can_connect_to_right();

                match (previous_joins_to_current, current_joins_to_next) {
                    (true, true) => forms.medial.unwrap_or(forms.final_form),
                    (true, false) => forms.final_form,
                    (false, true) => forms.initial.unwrap_or(forms.isolated),
                    (false, false) => forms.isolated,
                }
            } else {
                mirrored_bracket(letter.base).unwrap_or(letter.base)
            };

            cluster.push(shaped);
            cluster.extend(letter.marks.iter());
            cluster
        })
        .collect()
}

fn collect_letters(input: &str) -> Vec<ArabicLetter> {
    let chars: Vec<char> = input.chars().collect();
    let mut raw = Vec::new();
    let mut index = 0;

    while index < chars.len() {
        if is_digit(chars[index]) {
            let mut literal = String::new();
            while index < chars.len() && is_digit(chars[index]) {
                literal.push(chars[index]);
                index += 1;
            }
            raw.push(ArabicLetter::literal(literal));
            continue;
        }

        let base = chars[index];
        index += 1;
        let mut marks = Vec::new();
        while index < chars.len() && is_basic_arabic_mark(chars[index]) {
            marks.push(chars[index]);
            index += 1;
        }
        raw.push(ArabicLetter::from_with_marks(base, marks));
    }

    let mut letters = Vec::new();
    let mut index = 0;
    while index < raw.len() {
        if raw[index].base == 'ل' && index + 1 < raw.len() {
            if let Some(lam_alef) = LamAlef::for_alef(raw[index + 1].base) {
                let mut marks = raw[index].marks.clone();
                marks.extend(raw[index + 1].marks.iter().copied());
                letters.push(ArabicLetter::lam_alef('ل', lam_alef, marks));
                index += 2;
                continue;
            }
        }

        letters.push(raw[index].clone());
        index += 1;
    }

    letters
}

fn is_basic_arabic_mark(ch: char) -> bool {
    matches!(ch, '\u{064B}'..='\u{065F}' | '\u{0670}')
}

fn is_digit(ch: char) -> bool {
    ch.is_ascii_digit() || matches!(ch, '\u{0660}'..='\u{0669}' | '\u{06F0}'..='\u{06F9}')
}

fn mirrored_bracket(ch: char) -> Option<char> {
    match ch {
        '(' => Some(')'),
        ')' => Some('('),
        '[' => Some(']'),
        ']' => Some('['),
        '{' => Some('}'),
        '}' => Some('{'),
        '<' => Some('>'),
        '>' => Some('<'),
        _ => None,
    }
}

#[derive(Debug, Clone)]
struct ArabicLetter {
    base: char,
    marks: Vec<char>,
    literal: Option<String>,
    forms: Option<Forms>,
    lam_alef: Option<LamAlef>,
}

impl ArabicLetter {
    fn from_with_marks(base: char, marks: Vec<char>) -> Self {
        Self {
            base,
            marks,
            literal: None,
            forms: forms_for(base),
            lam_alef: None,
        }
    }

    fn lam_alef(base: char, lam_alef: LamAlef, marks: Vec<char>) -> Self {
        Self {
            base,
            marks,
            literal: None,
            forms: None,
            lam_alef: Some(lam_alef),
        }
    }

    fn literal(literal: String) -> Self {
        Self {
            base: '\0',
            marks: Vec::new(),
            literal: Some(literal),
            forms: None,
            lam_alef: None,
        }
    }

    fn can_connect_to_right(&self) -> bool {
        self.forms.is_some() || self.lam_alef.is_some()
    }

    fn can_connect_to_left(&self) -> bool {
        self.forms
            .is_some_and(|forms| forms.initial.is_some() && forms.medial.is_some())
    }
}

#[derive(Debug, Clone, Copy)]
struct Forms {
    isolated: char,
    final_form: char,
    initial: Option<char>,
    medial: Option<char>,
}

#[derive(Debug, Clone, Copy)]
struct LamAlef {
    isolated: char,
    final_form: char,
}

impl LamAlef {
    fn for_alef(alef: char) -> Option<Self> {
        match alef {
            'آ' => Some(Self {
                isolated: 'ﻵ',
                final_form: 'ﻶ',
            }),
            'أ' => Some(Self {
                isolated: 'ﻷ',
                final_form: 'ﻸ',
            }),
            'إ' => Some(Self {
                isolated: 'ﻹ',
                final_form: 'ﻺ',
            }),
            'ا' => Some(Self {
                isolated: 'ﻻ',
                final_form: 'ﻼ',
            }),
            _ => None,
        }
    }
}

fn dual(isolated: char, final_form: char, initial: char, medial: char) -> Forms {
    Forms {
        isolated,
        final_form,
        initial: Some(initial),
        medial: Some(medial),
    }
}

fn right_joining(isolated: char, final_form: char) -> Forms {
    Forms {
        isolated,
        final_form,
        initial: None,
        medial: None,
    }
}

fn forms_for(ch: char) -> Option<Forms> {
    match ch {
        'ا' => Some(right_joining('ﺍ', 'ﺎ')),
        'س' => Some(dual('ﺱ', 'ﺲ', 'ﺳ', 'ﺴ')),
        'ل' => Some(dual('ﻝ', 'ﻞ', 'ﻟ', 'ﻠ')),
        'م' => Some(dual('ﻡ', 'ﻢ', 'ﻣ', 'ﻤ')),
        _ => None,
    }
}
