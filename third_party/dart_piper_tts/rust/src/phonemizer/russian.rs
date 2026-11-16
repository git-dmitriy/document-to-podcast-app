const SOFTENING: &[char] = &[
    'б', 'в', 'д', 'з', 'к', 'л', 'м', 'н', 'п', 'р', 'с', 'т', 'ф', 'х',
];

const IOTATED: &[char] = &['е', 'ё', 'и', 'ю', 'я'];

#[derive(Clone, Copy, PartialEq, Eq)]
enum VowelPos {
    Stressed,
    Pretonic,
    Other,
}

pub(crate) struct RussianPhonemizer;

impl RussianPhonemizer {
    pub(crate) fn phonemize(word: &str) -> String {
        let (chars, stress) = normalize(word);
        if chars.is_empty() {
            return String::new();
        }

        let vowel_indexes: Vec<usize> = chars
            .iter()
            .enumerate()
            .filter_map(|(i, c)| is_vowel(*c).then_some(i))
            .collect();
        let stress = stress.unwrap_or_else(|| *vowel_indexes.last().unwrap_or(&0));

        let mut out = String::with_capacity(chars.len() * 2);
        let mut i = 0;
        while i < chars.len() {
            if i + 1 < chars.len() && chars[i] == 'д' && chars[i + 1] == 'ж' {
                out.push_str("dʒ");
                i += 2;
                continue;
            }

            let ch = chars[i];
            let prev = if i == 0 { None } else { Some(chars[i - 1]) };
            let next = chars.get(i + 1).copied();
            let pos = vowel_position(i, stress, &vowel_indexes);

            match ch {
                'а' => push_vowel(&mut out, reduce_a_o(pos, 'a'), pos),
                'б' => {
                    out.push('b');
                    push_palatal(&mut out, next);
                }
                'в' => {
                    out.push('v');
                    push_palatal(&mut out, next);
                }
                'г' => {
                    out.push('ɡ');
                    push_palatal(&mut out, next);
                }
                'д' => {
                    out.push('d');
                    push_palatal(&mut out, next);
                }
                'е' => push_iotated_vowel(&mut out, prev, reduce_e(pos), pos),
                'ё' => push_iotated_vowel(&mut out, prev, 'o', VowelPos::Stressed),
                'ж' => out.push('ʒ'),
                'з' => {
                    out.push('z');
                    push_palatal(&mut out, next);
                }
                'и' => push_vowel(&mut out, reduce_i(pos), pos),
                'й' => out.push('j'),
                'к' => {
                    out.push('k');
                    push_palatal(&mut out, next);
                }
                'л' => {
                    out.push('l');
                    push_palatal(&mut out, next);
                }
                'м' => {
                    out.push('m');
                    push_palatal(&mut out, next);
                }
                'н' => {
                    out.push('n');
                    push_palatal(&mut out, next);
                }
                'о' => push_vowel(&mut out, reduce_a_o(pos, 'o'), pos),
                'п' => {
                    out.push('p');
                    push_palatal(&mut out, next);
                }
                'р' => {
                    out.push('r');
                    push_palatal(&mut out, next);
                }
                'с' => {
                    out.push('s');
                    push_palatal(&mut out, next);
                }
                'т' => {
                    out.push('t');
                    push_palatal(&mut out, next);
                }
                'у' => push_vowel(&mut out, reduce_u(pos), pos),
                'ф' => {
                    out.push('f');
                    push_palatal(&mut out, next);
                }
                'х' => {
                    out.push('x');
                    push_palatal(&mut out, next);
                }
                'ц' => out.push_str("ts"),
                'ч' => out.push_str("tɕ"),
                'ш' => out.push('ʂ'),
                'щ' => out.push_str("ɕː"),
                'ъ' => {}
                'ы' => push_vowel(&mut out, 'ɨ', pos),
                'ь' => out.push('ʲ'),
                'э' => push_vowel(&mut out, reduce_e(pos), pos),
                'ю' => push_iotated_vowel(&mut out, prev, reduce_u(pos), pos),
                'я' => push_iotated_vowel(&mut out, prev, reduce_ya(pos), pos),
                other if other.is_ascii_alphabetic() => out.push(other),
                _ => {}
            }
            i += 1;
        }

        out.replace("ɕʲ", "ɕ")
            .replace("ʒʲ", "ʒ")
            .replace("ʂʲ", "ʂʲː")
            .replace("tɕ", "tɕʲ")
    }
}

fn normalize(word: &str) -> (Vec<char>, Option<usize>) {
    let mut chars = Vec::new();
    let mut stress = None;
    for ch in word.chars() {
        if ch == '\u{0301}' {
            if let Some(idx) = chars.iter().rposition(|c| is_vowel(*c)) {
                stress = Some(idx);
            }
            continue;
        }
        for lower in ch.to_lowercase() {
            if lower == 'ё' {
                stress = Some(chars.len());
            }
            chars.push(lower);
        }
    }
    (chars, stress)
}

fn vowel_position(index: usize, stress: usize, vowel_indexes: &[usize]) -> VowelPos {
    if !vowel_indexes.contains(&index) {
        return VowelPos::Other;
    }
    if index == stress {
        return VowelPos::Stressed;
    }
    let Some(stress_ord) = vowel_indexes.iter().position(|i| *i == stress) else {
        return VowelPos::Other;
    };
    let Some(this_ord) = vowel_indexes.iter().position(|i| *i == index) else {
        return VowelPos::Other;
    };
    if this_ord + 1 == stress_ord {
        VowelPos::Pretonic
    } else {
        VowelPos::Other
    }
}

fn reduce_a_o(pos: VowelPos, stressed: char) -> char {
    match pos {
        VowelPos::Stressed => stressed,
        VowelPos::Pretonic => 'ɐ',
        VowelPos::Other => 'ə',
    }
}

fn reduce_e(pos: VowelPos) -> char {
    match pos {
        VowelPos::Stressed => 'e',
        VowelPos::Pretonic | VowelPos::Other => 'ɪ',
    }
}

fn reduce_i(pos: VowelPos) -> char {
    match pos {
        VowelPos::Stressed => 'i',
        VowelPos::Pretonic | VowelPos::Other => 'ɪ',
    }
}

fn reduce_u(pos: VowelPos) -> char {
    match pos {
        VowelPos::Stressed => 'u',
        VowelPos::Pretonic | VowelPos::Other => 'ʊ',
    }
}

fn reduce_ya(pos: VowelPos) -> char {
    match pos {
        VowelPos::Stressed => 'a',
        VowelPos::Pretonic | VowelPos::Other => 'ɪ',
    }
}

fn push_vowel(out: &mut String, vowel: char, pos: VowelPos) {
    if pos == VowelPos::Stressed {
        out.push('ˈ');
    }
    out.push(vowel);
}

fn push_palatal(out: &mut String, next: Option<char>) {
    if matches!(next, Some(c) if IOTATED.contains(&c)) {
        out.push('ʲ');
    }
}

fn push_iotated_vowel(out: &mut String, prev: Option<char>, vowel: char, pos: VowelPos) {
    let needs_j = match prev {
        None => true,
        Some('ъ' | 'ь') => true,
        Some(c) if is_vowel(c) => true,
        Some(c) if SOFTENING.contains(&c) => false,
        _ => false,
    };
    if needs_j {
        out.push('j');
    }
    push_vowel(out, vowel, pos);
}

fn is_vowel(c: char) -> bool {
    matches!(
        c,
        'а' | 'е' | 'ё' | 'и' | 'о' | 'у' | 'ы' | 'э' | 'ю' | 'я'
    )
}

#[cfg(test)]
mod tests {
    use super::RussianPhonemizer;

    #[test]
    fn applies_akanye_on_unstressed_o() {
        let milk = RussianPhonemizer::phonemize("молоко");
        assert_eq!(milk, "məlɐkˈo");

        let good = RussianPhonemizer::phonemize("хорошо");
        assert_eq!(good, "xərɐʂˈo");
    }

    #[test]
    fn keeps_yo_stressed() {
        let word = RussianPhonemizer::phonemize("ёлка");
        assert!(word.contains("ˈo"), "{word}");
        assert!(word.starts_with('j') || word.contains('j'), "{word}");
    }

    #[test]
    fn respects_explicit_stress_mark() {
        // го́род — stress on first о
        let word = RussianPhonemizer::phonemize("го\u{0301}род");
        assert!(word.starts_with("ɡˈo") || word.contains("ˈo"), "{word}");
    }

    #[test]
    fn phonemes_are_in_irina_alphabet() {
        const ALLOWED: &str = "abcdefghijklmnopqrstuvwxyzæçðøħŋœǀǁǂǃɐɑɒɓɔɕɖɗɘəɚɛɜɞɟɠɡɢɣɤɥɦɧɨɪɫɬɭɮɯɰɱɲɳɴɵɶɸɹɺɻɽɾʀʁʂʃʄʈʉʊʋʌʍʎʏʐʑʒʔʕʘʙʛʜʝʟʡʢʰʲˈˌːˑ˞ˤ̧̩̪̯̃βθχᵻ↓ⱱ _^,.;:!?-'()";
        let sample =
            RussianPhonemizer::phonemize("Привет мир Это русский текст щётка молоко хорошо");
        for ch in sample.chars() {
            assert!(
                ALLOWED.contains(ch),
                "unexpected phoneme {ch:?} in {sample}"
            );
        }
    }
}
