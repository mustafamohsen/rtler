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
    let shaped: Vec<char> = shape(input);
    TransformResult {
        output: shaped.into_iter().rev().collect(),
        warnings: Vec::new(),
    }
}

fn shape(input: &str) -> Vec<char> {
    let letters = collect_letters(input);

    letters
        .iter()
        .enumerate()
        .map(|(index, letter)| {
            if let Some(ligature) = letter.lam_alef {
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
                letter.base
            }
        })
        .collect()
}

fn collect_letters(input: &str) -> Vec<ArabicLetter> {
    let chars: Vec<char> = input.chars().collect();
    let mut letters = Vec::new();
    let mut index = 0;

    while index < chars.len() {
        if chars[index] == 'ل' && index + 1 < chars.len() && chars[index + 1] == 'ا' {
            letters.push(ArabicLetter::lam_alef(chars[index]));
            index += 2;
        } else {
            letters.push(ArabicLetter::from(chars[index]));
            index += 1;
        }
    }

    letters
}

#[derive(Debug, Clone, Copy)]
struct ArabicLetter {
    base: char,
    forms: Option<Forms>,
    lam_alef: Option<LamAlef>,
}

impl ArabicLetter {
    fn from(base: char) -> Self {
        Self {
            base,
            forms: forms_for(base),
            lam_alef: None,
        }
    }

    fn lam_alef(base: char) -> Self {
        Self {
            base,
            forms: None,
            lam_alef: Some(LamAlef {
                isolated: 'ﻻ',
                final_form: 'ﻼ',
            }),
        }
    }

    fn can_connect_to_right(self) -> bool {
        self.forms.is_some() || self.lam_alef.is_some()
    }

    fn can_connect_to_left(self) -> bool {
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
