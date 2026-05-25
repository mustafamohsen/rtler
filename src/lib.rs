use std::ffi::{CStr, CString};
use std::os::raw::c_char;

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

/// Transforms a UTF-8 C string with RTLer.
///
/// Returns a newly allocated C string that must be freed with
/// [`rtler_free_string`], or null if `input` is null or not valid UTF-8.
///
/// # Safety
///
/// `input` must either be null or point to a valid, NUL-terminated C string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn rtler_transform_text(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }

    let input = unsafe { CStr::from_ptr(input) };
    let Ok(input) = input.to_str() else {
        return std::ptr::null_mut();
    };

    match CString::new(transform(input).output) {
        Ok(output) => output.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Frees a string returned by [`rtler_transform_text`].
///
/// # Safety
///
/// `ptr` must either be null or a pointer previously returned by
/// [`rtler_transform_text`] that has not already been freed.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn rtler_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }

    unsafe {
        drop(CString::from_raw(ptr));
    }
}

pub fn transform(input: &str) -> TransformResult {
    let mut warnings = Vec::new();
    let output = input
        .split('\n')
        .map(|line| transform_line(line, &mut warnings))
        .collect::<Vec<_>>()
        .join("\n");

    TransformResult { output, warnings }
}

fn transform_line(input: &str, warnings: &mut Vec<Warning>) -> String {
    let normalized = normalize_presentation_forms(input);
    let shaped = shape(&normalized, warnings);
    shaped.into_iter().rev().collect::<String>()
}

fn normalize_presentation_forms(input: &str) -> String {
    input.chars().flat_map(normalized_chars).collect()
}

fn normalized_chars(ch: char) -> Vec<char> {
    match ch {
        'ﻵ' | 'ﻶ' => vec!['ل', 'آ'],
        'ﻷ' | 'ﻸ' => vec!['ل', 'أ'],
        'ﻹ' | 'ﻺ' => vec!['ل', 'إ'],
        'ﻻ' | 'ﻼ' => vec!['ل', 'ا'],
        'ﺀ' => vec!['ء'],
        'ﺁ' | 'ﺂ' => vec!['آ'],
        'ﺃ' | 'ﺄ' => vec!['أ'],
        'ﺅ' | 'ﺆ' => vec!['ؤ'],
        'ﺇ' | 'ﺈ' => vec!['إ'],
        'ﺉ' | 'ﺊ' | 'ﺋ' | 'ﺌ' => vec!['ئ'],
        'ﺍ' | 'ﺎ' => vec!['ا'],
        'ﺏ' | 'ﺐ' | 'ﺑ' | 'ﺒ' => vec!['ب'],
        'ﺓ' | 'ﺔ' => vec!['ة'],
        'ﺕ' | 'ﺖ' | 'ﺗ' | 'ﺘ' => vec!['ت'],
        'ﺙ' | 'ﺚ' | 'ﺛ' | 'ﺜ' => vec!['ث'],
        'ﺝ' | 'ﺞ' | 'ﺟ' | 'ﺠ' => vec!['ج'],
        'ﺡ' | 'ﺢ' | 'ﺣ' | 'ﺤ' => vec!['ح'],
        'ﺥ' | 'ﺦ' | 'ﺧ' | 'ﺨ' => vec!['خ'],
        'ﺩ' | 'ﺪ' => vec!['د'],
        'ﺫ' | 'ﺬ' => vec!['ذ'],
        'ﺭ' | 'ﺮ' => vec!['ر'],
        'ﺯ' | 'ﺰ' => vec!['ز'],
        'ﺱ' | 'ﺲ' | 'ﺳ' | 'ﺴ' => vec!['س'],
        'ﺵ' | 'ﺶ' | 'ﺷ' | 'ﺸ' => vec!['ش'],
        'ﺹ' | 'ﺺ' | 'ﺻ' | 'ﺼ' => vec!['ص'],
        'ﺽ' | 'ﺾ' | 'ﺿ' | 'ﻀ' => vec!['ض'],
        'ﻁ' | 'ﻂ' | 'ﻃ' | 'ﻄ' => vec!['ط'],
        'ﻅ' | 'ﻆ' | 'ﻇ' | 'ﻈ' => vec!['ظ'],
        'ﻉ' | 'ﻊ' | 'ﻋ' | 'ﻌ' => vec!['ع'],
        'ﻍ' | 'ﻎ' | 'ﻏ' | 'ﻐ' => vec!['غ'],
        'ﻑ' | 'ﻒ' | 'ﻓ' | 'ﻔ' => vec!['ف'],
        'ﻕ' | 'ﻖ' | 'ﻗ' | 'ﻘ' => vec!['ق'],
        'ﻙ' | 'ﻚ' | 'ﻛ' | 'ﻜ' => vec!['ك'],
        'ﻝ' | 'ﻞ' | 'ﻟ' | 'ﻠ' => vec!['ل'],
        'ﻡ' | 'ﻢ' | 'ﻣ' | 'ﻤ' => vec!['م'],
        'ﻥ' | 'ﻦ' | 'ﻧ' | 'ﻨ' => vec!['ن'],
        'ﻩ' | 'ﻪ' | 'ﻫ' | 'ﻬ' => vec!['ه'],
        'ﻭ' | 'ﻮ' => vec!['و'],
        'ﻯ' | 'ﻰ' => vec!['ى'],
        'ﻱ' | 'ﻲ' | 'ﻳ' | 'ﻴ' => vec!['ي'],
        _ => vec![ch],
    }
}

fn shape(input: &str, warnings: &mut Vec<Warning>) -> Vec<String> {
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
                if is_unsupported_arabic_script_letter(letter.base) {
                    warnings.push(Warning {
                        character: letter.base,
                        message: "no presentation-form mapping; passed through unchanged"
                            .to_string(),
                    });
                }
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
        if is_ltr_token_start(chars[index]) {
            let mut literal = String::new();
            while index < chars.len() && is_ltr_token_char(chars[index]) {
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
        let lam_alef = (raw[index].base == 'ل' && index + 1 < raw.len())
            .then(|| LamAlef::for_alef(raw[index + 1].base))
            .flatten();

        if let Some(lam_alef) = lam_alef {
            let mut marks = raw[index].marks.clone();
            marks.extend(raw[index + 1].marks.iter().copied());
            letters.push(ArabicLetter::lam_alef('ل', lam_alef, marks));
            index += 2;
            continue;
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

fn is_ltr_token_start(ch: char) -> bool {
    ch.is_ascii_alphanumeric() || is_digit(ch) || matches!(ch, '@' | '#')
}

fn is_ltr_token_char(ch: char) -> bool {
    ch.is_ascii_alphanumeric() || is_numeric_run_char(ch) || matches!(ch, '@' | '#' | '-' | '_')
}

fn is_numeric_run_char(ch: char) -> bool {
    is_digit(ch)
        || matches!(
            ch,
            '.' | ',' | '/' | ':' | '%' | '\u{066B}' | '\u{066C}' | '\u{066A}'
        )
}

fn is_unsupported_arabic_script_letter(ch: char) -> bool {
    matches!(ch, '\u{0600}'..='\u{06FF}' | '\u{0750}'..='\u{077F}' | '\u{08A0}'..='\u{08FF}')
        && !is_basic_arabic_mark(ch)
        && !is_arabic_punctuation_or_symbol(ch)
        && !is_digit(ch)
}

fn is_arabic_punctuation_or_symbol(ch: char) -> bool {
    matches!(
        ch,
        '\u{060C}' | '\u{061B}' | '\u{061F}' | '\u{0640}' | '\u{066A}'..='\u{066D}' | '\u{06D4}'
    )
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
        'ء' => Some(right_joining('ﺀ', 'ﺀ')),
        'آ' => Some(right_joining('ﺁ', 'ﺂ')),
        'أ' => Some(right_joining('ﺃ', 'ﺄ')),
        'ؤ' => Some(right_joining('ﺅ', 'ﺆ')),
        'إ' => Some(right_joining('ﺇ', 'ﺈ')),
        'ئ' => Some(dual('ﺉ', 'ﺊ', 'ﺋ', 'ﺌ')),
        'ا' => Some(right_joining('ﺍ', 'ﺎ')),
        'ب' => Some(dual('ﺏ', 'ﺐ', 'ﺑ', 'ﺒ')),
        'ة' => Some(right_joining('ﺓ', 'ﺔ')),
        'ت' => Some(dual('ﺕ', 'ﺖ', 'ﺗ', 'ﺘ')),
        'ث' => Some(dual('ﺙ', 'ﺚ', 'ﺛ', 'ﺜ')),
        'ج' => Some(dual('ﺝ', 'ﺞ', 'ﺟ', 'ﺠ')),
        'ح' => Some(dual('ﺡ', 'ﺢ', 'ﺣ', 'ﺤ')),
        'خ' => Some(dual('ﺥ', 'ﺦ', 'ﺧ', 'ﺨ')),
        'د' => Some(right_joining('ﺩ', 'ﺪ')),
        'ذ' => Some(right_joining('ﺫ', 'ﺬ')),
        'ر' => Some(right_joining('ﺭ', 'ﺮ')),
        'ز' => Some(right_joining('ﺯ', 'ﺰ')),
        'س' => Some(dual('ﺱ', 'ﺲ', 'ﺳ', 'ﺴ')),
        'ش' => Some(dual('ﺵ', 'ﺶ', 'ﺷ', 'ﺸ')),
        'ص' => Some(dual('ﺹ', 'ﺺ', 'ﺻ', 'ﺼ')),
        'ض' => Some(dual('ﺽ', 'ﺾ', 'ﺿ', 'ﻀ')),
        'ط' => Some(dual('ﻁ', 'ﻂ', 'ﻃ', 'ﻄ')),
        'ظ' => Some(dual('ﻅ', 'ﻆ', 'ﻇ', 'ﻈ')),
        'ع' => Some(dual('ﻉ', 'ﻊ', 'ﻋ', 'ﻌ')),
        'غ' => Some(dual('ﻍ', 'ﻎ', 'ﻏ', 'ﻐ')),
        'ف' => Some(dual('ﻑ', 'ﻒ', 'ﻓ', 'ﻔ')),
        'ق' => Some(dual('ﻕ', 'ﻖ', 'ﻗ', 'ﻘ')),
        'ك' => Some(dual('ﻙ', 'ﻚ', 'ﻛ', 'ﻜ')),
        'ل' => Some(dual('ﻝ', 'ﻞ', 'ﻟ', 'ﻠ')),
        'م' => Some(dual('ﻡ', 'ﻢ', 'ﻣ', 'ﻤ')),
        'ن' => Some(dual('ﻥ', 'ﻦ', 'ﻧ', 'ﻨ')),
        'ه' => Some(dual('ﻩ', 'ﻪ', 'ﻫ', 'ﻬ')),
        'و' => Some(right_joining('ﻭ', 'ﻮ')),
        'ى' => Some(right_joining('ﻯ', 'ﻰ')),
        'ي' => Some(dual('ﻱ', 'ﻲ', 'ﻳ', 'ﻴ')),
        'پ' => Some(dual('ﭖ', 'ﭗ', 'ﭘ', 'ﭙ')),
        'چ' => Some(dual('ﭺ', 'ﭻ', 'ﭼ', 'ﭽ')),
        'ژ' => Some(right_joining('ﮊ', 'ﮋ')),
        'ک' => Some(dual('ﮎ', 'ﮏ', 'ﮐ', 'ﮑ')),
        'گ' => Some(dual('ﮒ', 'ﮓ', 'ﮔ', 'ﮕ')),
        'ی' => Some(dual('ﯼ', 'ﯽ', 'ﯾ', 'ﯿ')),
        'ٹ' => Some(dual('ﭦ', 'ﭧ', 'ﭨ', 'ﭩ')),
        'ڈ' => Some(right_joining('ﮈ', 'ﮉ')),
        'ڑ' => Some(right_joining('ﮌ', 'ﮍ')),
        'ں' => Some(right_joining('ﮞ', 'ﮟ')),
        'ہ' => Some(dual('ﮦ', 'ﮧ', 'ﮨ', 'ﮩ')),
        'ھ' => Some(dual('ﮪ', 'ﮫ', 'ﮬ', 'ﮭ')),
        'ے' => Some(right_joining('ﮮ', 'ﮯ')),
        'ۓ' => Some(right_joining('ﮰ', 'ﮱ')),
        _ => None,
    }
}
