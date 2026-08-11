/// Constants for the English G2P implementation
// No library directive needed

/// Diphthongs
library;

const Set<String> diphthongs = {'A', 'I', 'O', 'Q', 'W', 'Y', 'ʤ', 'ʧ'};

/// Stress marks
const String primaryStress = 'ˈ';
const String secondaryStress = 'ˌ';
const List<String> stresses = [secondaryStress, primaryStress];

/// Vowels
const Set<String> vowels = {
  'A',
  'I',
  'O',
  'Q',
  'W',
  'Y',
  'a',
  'i',
  'u',
  'æ',
  'ɑ',
  'ɒ',
  'ɔ',
  'ə',
  'ɛ',
  'ɜ',
  'ɪ',
  'ʊ',
  'ʌ',
  'ᵻ',
};

/// Consonants
const Set<String> consonants = {
  'b',
  'd',
  'f',
  'h',
  'j',
  'k',
  'l',
  'm',
  'n',
  'p',
  's',
  't',
  'v',
  'w',
  'z',
  'ð',
  'ŋ',
  'ɡ',
  'ɹ',
  'ɾ',
  'ʃ',
  'ʒ',
  'ʤ',
  'ʧ',
  'θ',
};

/// American English phoneme set
const Set<String> usVocab = {
  'A',
  'I',
  'O',
  'W',
  'Y',
  'b',
  'd',
  'f',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'p',
  's',
  't',
  'u',
  'v',
  'w',
  'z',
  'æ',
  'ð',
  'ŋ',
  'ɑ',
  'ɔ',
  'ə',
  'ɛ',
  'ɜ',
  'ɡ',
  'ɪ',
  'ɹ',
  'ɾ',
  'ʃ',
  'ʊ',
  'ʌ',
  'ʒ',
  'ʤ',
  'ʧ',
  'ˈ',
  'ˌ',
  'θ',
  'ᵊ',
  'ᵻ',
  'ʔ',
};

/// British English phoneme set
const Set<String> gbVocab = {
  'A',
  'I',
  'Q',
  'W',
  'Y',
  'a',
  'b',
  'd',
  'f',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'p',
  's',
  't',
  'u',
  'v',
  'w',
  'z',
  'ð',
  'ŋ',
  'ɑ',
  'ɒ',
  'ɔ',
  'ə',
  'ɛ',
  'ɜ',
  'ɡ',
  'ɪ',
  'ɹ',
  'ʃ',
  'ʊ',
  'ʌ',
  'ʒ',
  'ʤ',
  'ʧ',
  'ˈ',
  'ˌ',
  'ː',
  'θ',
  'ᵊ',
};

/// Punctuation tags
const Set<String> punctTags = {
  '.',
  ',',
  '-LRB-',
  '-RRB-',
  '``',
  '""',
  "''",
  ':',
  '\$',
  '#',
  'NFP',
};

/// Punctuation tag phonemes mapping
const Map<String, String> punctTagPhonemes = {
  '-LRB-': '(',
  '-RRB-': ')',
  '``': '\u2014',
  '""': '\u2015',
  "''": '\u2015',
};

/// Currency symbols and their word representations
const Map<String, List<String>> currencies = {
  '\$': ['dollar', 'cent'],
  '£': ['pound', 'pence'],
  '€': ['euro', 'cent'],
};

/// Ordinal suffixes
const Set<String> ordinals = {'st', 'nd', 'rd', 'th'};

/// Additional symbols and their word representations
const Map<String, String> addSymbols = {'.': 'dot', '/': 'slash'};

/// Common symbols and their word representations
const Map<String, String> symbols = {
  '%': 'percent',
  '&': 'and',
  '+': 'plus',
  '@': 'at',
};

/// Regular expression for links in markdown format
final RegExp linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]*)\)');

/// Regular expression for digits
final RegExp digitRegex = RegExp(r'^[0-9]+$');

/// Subtoken junk characters
const Set<String> subtokenJunks = {"'", ',', '-', '.', '_', '/'};

/// Punctuation characters
const Set<String> puncts = {';', ':', ',', '.', '!', '?', '—', '…', '"'};

/// Non-quote punctuation characters
final Set<String> nonQuotePuncts =
    puncts.where((p) => !{'"'}.contains(p)).toSet();
