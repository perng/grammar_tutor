#!/usr/bin/env python3
"""
Filter JSON files to only contain entries with words from the vocabulary list.
Allows word variations (plurals, tenses, etc.)

Usage:
    python filter_vocab.py --dry-run   # Preview what would be removed
    python filter_vocab.py             # Actually filter the files
"""

import json
import re
import os
from pathlib import Path

# Irregular verb mappings (past/participle forms -> base form)
IRREGULAR_VERBS = {
    'ate': 'eat', 'eaten': 'eat',
    'awoke': 'awake', 'awoken': 'awake',
    'became': 'become', 'becomes': 'become',
    'began': 'begin', 'begun': 'begin',
    'bent': 'bend',
    'bit': 'bite', 'bitten': 'bite',
    'bled': 'bleed',
    'blew': 'blow', 'blown': 'blow',
    'broke': 'break', 'broken': 'break',
    'brought': 'bring',
    'built': 'build',
    'bought': 'buy',
    'caught': 'catch',
    'came': 'come',
    'chose': 'choose', 'chosen': 'choose',
    'did': 'do', 'done': 'do',
    'drank': 'drink', 'drunk': 'drink',
    'drew': 'draw', 'drawn': 'draw',
    'drove': 'drive', 'driven': 'drive',
    'dug': 'dig',
    'fell': 'fall', 'fallen': 'fall',
    'fed': 'feed',
    'felt': 'feel',
    'flew': 'fly', 'flown': 'fly',
    'forgot': 'forget', 'forgotten': 'forget',
    'forgave': 'forgive', 'forgiven': 'forgive',
    'froze': 'freeze', 'frozen': 'freeze',
    'gave': 'give', 'given': 'give',
    'got': 'get', 'gotten': 'get',
    'grew': 'grow', 'grown': 'grow',
    'had': 'have', 'having': 'have',
    'heard': 'hear',
    'held': 'hold',
    'hid': 'hide', 'hidden': 'hide',
    'hit': 'hit',
    'hung': 'hang',
    'kept': 'keep',
    'knew': 'know', 'known': 'know',
    'led': 'lead',
    'left': 'leave',
    'lent': 'lend',
    'let': 'let',
    'lit': 'light',
    'lost': 'lose',
    'made': 'make',
    'meant': 'mean',
    'met': 'meet',
    'paid': 'pay',
    'put': 'put',
    'ran': 'run',
    'rang': 'ring', 'rung': 'ring',
    'read': 'read',  # Past tense pronounced differently
    'rode': 'ride', 'ridden': 'ride',
    'rose': 'rise', 'risen': 'rise',
    'said': 'say',
    'sang': 'sing', 'sung': 'sing',
    'sank': 'sink', 'sunk': 'sink', 'sunken': 'sink',
    'sat': 'sit',
    'saw': 'see', 'seen': 'see',
    'sent': 'send',
    'shone': 'shine',
    'shook': 'shake', 'shaken': 'shake',
    'shot': 'shoot',
    'showed': 'show', 'shown': 'show',
    'slept': 'sleep',
    'slid': 'slide',
    'sold': 'sell',
    'spent': 'spend',
    'spoke': 'speak', 'spoken': 'speak',
    'stood': 'stand',
    'stole': 'steal', 'stolen': 'steal',
    'stuck': 'stick',
    'stung': 'sting',
    'swam': 'swim', 'swum': 'swim',
    'swept': 'sweep',
    'swung': 'swing',
    'taught': 'teach',
    'thought': 'think',
    'threw': 'throw', 'thrown': 'throw',
    'told': 'tell',
    'took': 'take', 'taken': 'take',
    'understood': 'understand',
    'woke': 'wake', 'woken': 'wake',
    'won': 'win',
    'wore': 'wear', 'worn': 'wear',
    'went': 'go', 'gone': 'go',
    'wrote': 'write', 'written': 'write',
}

# Irregular noun plurals (plural -> singular)
IRREGULAR_PLURALS = {
    'children': 'child',
    'men': 'man',
    'women': 'woman',
    'feet': 'foot',
    'teeth': 'tooth',
    'mice': 'mouse',
    'geese': 'goose',
    'oxen': 'ox',
    'sheep': 'sheep',
    'deer': 'deer',
    'fish': 'fish',
    'species': 'species',
    'series': 'series',
}

# Essential function words that should always be allowed
# These are basic grammar words that might not be in a vocabulary list
FUNCTION_WORDS = {
    # Articles
    'a', 'an', 'the',
    
    # Conjunctions
    'and', 'or', 'but', 'nor', 'yet', 'so', 'for',
    
    # Prepositions
    'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'as',
    'into', 'onto', 'upon', 'about', 'above', 'below', 'between', 'through',
    'during', 'after', 'before', 'until', 'since', 'while', 'among',
    
    # Pronouns
    'i', 'me', 'my', 'mine', 'myself',
    'you', 'your', 'yours', 'yourself', 'yourselves',
    'he', 'him', 'his', 'himself',
    'she', 'her', 'hers', 'herself',
    'it', 'its', 'itself',
    'we', 'us', 'our', 'ours', 'ourselves',
    'they', 'them', 'their', 'theirs', 'themselves',
    'who', 'whom', 'whose', 'which', 'what', 'that',
    'this', 'these', 'those',
    
    # Be verbs
    'be', 'am', 'is', 'are', 'was', 'were', 'been', 'being',
    
    # Have verbs
    'have', 'has', 'had', 'having',
    
    # Do verbs
    'do', 'does', 'did', 'done', 'doing',
    
    # Modal verbs
    'will', 'would', 'shall', 'should', 'can', 'could', 'may', 'might', 'must',
    
    # Common adverbs
    'not', 'no', 'yes', 'very', 'just', 'also', 'only', 'even', 'still',
    'here', 'there', 'now', 'then', 'when', 'where', 'why', 'how',
    'up', 'down', 'out', 'off', 'over', 'under', 'again', 'once',
    'too', 'so', 'as', 'if',
    
    # Quantifiers
    'all', 'each', 'every', 'both', 'few', 'more', 'most', 'some', 'any',
    'other', 'such', 'many', 'much', 'less', 'least', 'enough',
    
    # Time words
    'today', 'tomorrow', 'yesterday', 'always', 'never', 'sometimes',
    'often', 'usually', 'seldom', 'rarely',
    
    # Common contractions
    "don't", "doesn't", "didn't", "won't", "wouldn't", "can't", "couldn't",
    "shouldn't", "mustn't", "isn't", "aren't", "wasn't", "weren't",
    "hasn't", "haven't", "hadn't", "i'm", "i've", "i'll", "i'd",
    "you're", "you've", "you'll", "you'd", "he's", "he'll", "he'd",
    "she's", "she'll", "she'd", "it's", "it'll", "we're", "we've",
    "we'll", "we'd", "they're", "they've", "they'll", "they'd",
    "that's", "there's", "here's", "what's", "who's", "let's",
    
    # Ordinal suffixes and abbreviations
    'st', 'nd', 'rd', 'th',
    'mr', 'mrs', 'ms', 'dr',
    'ok', 'okay', 'oh', 'ah', 'wow', 'um', 'uh', 'hmm',
    "o'clock", "willn't",  # contractions
    
    # Common proper nouns - Places
    'london', 'paris', 'tokyo', 'rome', 'york', 'hawaii', 'taiwan',
    'france', 'england', 'japan', 'china', 'spain', 'italy', 'germany',
    'america', 'europe', 'asia', 'africa',
    
    # Famous people / cultural references
    'shakespeare', 'hamlet', 'rowling', 'potter', 'harry',
    'vinci', 'mona', 'lisa', 'titanic',
    'google', 'santa',
    
    # Common story character names
    'alice', 'bob', 'charlie', 'david', 'emma', 'frank', 'grace',
    'henry', 'ivy', 'jack', 'kate', 'lily', 'mary', 'nick',
    'olivia', 'peter', 'rachel', 'sam', 'tom', 'victor', 'wendy',
    'ben', 'billy', 'bobby', 'danny', 'eddie', 'freddy', 'gary',
    'jimmy', 'johnny', 'kenny', 'larry', 'mike', 'nicky', 'paul',
    'sally', 'sandy', 'teddy', 'tim', 'tony', 'wally', 'willy',
    'anna', 'bella', 'betty', 'daisy', 'ella', 'faye', 'jenny',
    'julie', 'luna', 'maria', 'nancy', 'penny', 'rosa', 'sarah',
    'annie', 'benny', 'cappy', 'dolly', 'gerry', 'hugo', 'jerry',
    'kevin', 'kira', 'lulu', 'marina', 'max', 'milo', 'ollie', 'olly',
    'otis', 'percy', 'perry', 'pip', 'rosie', 'sammy', 'squeaky',
    'tina', 'toby', 'wanda', 'zane',
    
    # Fantasy/story creature names (characters)
    'draco', 'tobias', 'barnaby', 'gizmo', 'faye', 'luna',
    
    # Celebrity names for grammar examples
    'angelina', 'brad', 'jolie', 'pitt', 'meryl', 'streep', 'cruise',
    'smith', 'jones', 'chen', 'lee', 'van',
    
    # Possessive forms of common names
    "alice's", "mary's", "tom's", "jerry's", "sally's", "benny's",
    "gavin's", "ella's", "leo's", "luna's", "cappy's",
    
    # Additional missing names
    'gavin', 'leo', 'john', 'dash', 'kiwi', 'groundhog',
    
    # Irregular plurals that might appear
    'childrens', 'mens', 'womens',  # common misspellings/informal forms
    
    # Miscellaneous common words
    'ai', 'avenue', 'cigarette', 'graduated', 'assuming', 'aches',
    'da',  # as in "da Vinci"
}




def load_vocabulary(vocab_path: str) -> set:
    """Load vocabulary words from file."""
    vocab = set()
    with open(vocab_path, 'r', encoding='utf-8') as f:
        for line in f:
            word = line.strip().lower()
            if word:
                vocab.add(word)
    return vocab


def get_base_forms(word: str) -> list:
    """Generate possible base forms of a word."""
    word_lower = word.lower()
    forms = [word_lower]
    
    # Check irregular verb mapping
    if word_lower in IRREGULAR_VERBS:
        forms.append(IRREGULAR_VERBS[word_lower])
    
    # Check irregular plural mapping
    if word_lower in IRREGULAR_PLURALS:
        forms.append(IRREGULAR_PLURALS[word_lower])
    
    # Remove common suffixes
    suffixes = [
        ('ies', 'y'),      # carries -> carry
        ('ied', 'y'),      # carried -> carry
        ('ves', 'f'),      # leaves -> leaf
        ('ves', 'fe'),     # knives -> knife
        ('ing', ''),       # running -> runn
        ('ing', 'e'),      # making -> make
        ('ed', ''),        # walked -> walk
        ('ed', 'e'),       # liked -> like
        ('es', ''),        # watches -> watch
        ('s', ''),         # cats -> cat
        ('er', ''),        # bigger -> bigg
        ('er', 'e'),       # nicer -> nice
        ('est', ''),       # biggest -> bigg
        ('est', 'e'),      # nicest -> nice
        ('ly', ''),        # quickly -> quick
        ('ness', ''),      # happiness -> happi
        ('ment', ''),      # enjoyment -> enjoy
        ('ful', ''),       # beautiful -> beauti
        ('less', ''),      # careless -> care
        ("'s", ''),        # possessive
        ("s'", ''),        # plural possessive
    ]
    
    for suffix, replacement in suffixes:
        if word_lower.endswith(suffix) and len(word_lower) > len(suffix) + 1:
            base = word_lower[:-len(suffix)] + replacement
            forms.append(base)
            # Handle doubled consonants
            if base and len(base) >= 2 and base[-1] == base[-2] and base[-1] in 'bcdfgklmnprstv':
                forms.append(base[:-1])
    
    # Handle -y to -i changes (happier -> happy)
    if word_lower.endswith('ier') or word_lower.endswith('iest'):
        if word_lower.endswith('ier'):
            forms.append(word_lower[:-3] + 'y')
        else:
            forms.append(word_lower[:-4] + 'y')
    
    return list(set(forms))


def is_word_allowed(word: str, vocab: set) -> bool:
    """Check if a word is in the vocabulary or is a valid variation."""
    word_lower = word.lower()
    
    # Skip empty, single letters, numbers
    if not word_lower or len(word_lower) <= 1:
        return True
    if not any(c.isalpha() for c in word_lower):
        return True
    
    # Check function words
    if word_lower in FUNCTION_WORDS:
        return True
    
    # Check direct match in vocab
    if word_lower in vocab:
        return True
    
    # Check if any base form is in vocab
    for base in get_base_forms(word_lower):
        if base in vocab:
            return True
    
    # For possessive forms (word's), check the base word
    if "'s" in word_lower or "'" in word_lower:
        base_word = word_lower.replace("'s", "").replace("'", "")
        if base_word in vocab:
            return True
        for base in get_base_forms(base_word):
            if base in vocab:
                return True
    
    # For hyphenated words, check each part
    if '-' in word_lower:
        parts = word_lower.split('-')
        if all(is_word_allowed(part, vocab) for part in parts if part):
            return True
    
    return False


def extract_words_from_text(text: str) -> list:
    """Extract words from text, handling brackets and special characters."""
    # Remove JSON escape sequences
    text = text.replace('\\n', ' ').replace('\\t', ' ')
    
    # Handle bracket notations like [word1|word2|word3]
    bracket_pattern = r'\[([^\]]+)\]'
    for bracket in re.findall(bracket_pattern, text):
        words = bracket.split('|')
        text = text.replace('[' + bracket + ']', ' ' + ' '.join(words) + ' ')
    
    # Remove markdown formatting
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    text = re.sub(r'#+ ', '', text)
    
    # Extract words (including contractions and hyphenated words)
    words = re.findall(r"[a-zA-Z]+(?:'[a-zA-Z]+)?(?:-[a-zA-Z]+)*", text)
    
    return words


def check_entry_words(entry: dict, vocab: set) -> tuple:
    """Check all words in an entry. Returns (is_valid, unknown_words)."""
    unknown_words = set()
    
    # Only check content field (main text, not explanations)
    if 'content' in entry:
        words = extract_words_from_text(entry['content'])
        for word in words:
            if not is_word_allowed(word, vocab):
                unknown_words.add(word.lower())
    
    return len(unknown_words) == 0, unknown_words


def filter_json_file(json_path: str, vocab: set, dry_run: bool = False) -> dict:
    """Filter a JSON file, keeping only entries with vocabulary words."""
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if not isinstance(data, list):
        print(f"  Skipping {json_path}: not a list")
        return {'kept': 0, 'removed': 0, 'unknown_words': set()}
    
    kept_entries = []
    removed_entries = []
    all_unknown_words = set()
    
    for entry in data:
        is_valid, unknown_words = check_entry_words(entry, vocab)
        if is_valid:
            kept_entries.append(entry)
        else:
            removed_entries.append(entry)
            all_unknown_words.update(unknown_words)
            title = entry.get('title', entry.get('id', 'unknown'))
            print(f"    Removing '{title}': unknown words: {', '.join(sorted(unknown_words)[:10])}")
    
    if not dry_run and removed_entries:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(kept_entries, f, ensure_ascii=False, indent=4)
    
    return {
        'kept': len(kept_entries),
        'removed': len(removed_entries),
        'unknown_words': all_unknown_words
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Filter JSON files by vocabulary')
    parser.add_argument('--dry-run', action='store_true', 
                        help='Show what would be removed without modifying files')
    args = parser.parse_args()
    
    # Paths
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / 'assets' / 'data'
    vocab_path = data_dir / 'vocab.txt'
    
    # Load vocabulary
    print(f"Loading vocabulary from {vocab_path}")
    vocab = load_vocabulary(vocab_path)
    print(f"Loaded {len(vocab)} vocabulary words")
    
    # Find all JSON files
    json_files = list(data_dir.glob('*.json'))
    print(f"Found {len(json_files)} JSON files")
    
    total_kept = 0
    total_removed = 0
    all_unknown = set()
    
    for json_path in sorted(json_files):
        print(f"\nProcessing {json_path.name}...")
        result = filter_json_file(str(json_path), vocab, dry_run=args.dry_run)
        total_kept += result['kept']
        total_removed += result['removed']
        all_unknown.update(result['unknown_words'])
        print(f"  Kept: {result['kept']}, Removed: {result['removed']}")
    
    print(f"\n{'='*50}")
    print(f"Total entries kept: {total_kept}")
    print(f"Total entries removed: {total_removed}")
    print(f"Total unique unknown words: {len(all_unknown)}")
    
    if all_unknown:
        print(f"\nUnknown words not in vocabulary ({len(all_unknown)}):")
        for word in sorted(all_unknown):
            print(f"  {word}")
    
    if args.dry_run:
        print("\n[DRY RUN - No files were modified]")
    else:
        if total_removed > 0:
            print("\n[Files have been updated]")
        else:
            print("\n[No changes needed - all content is within vocabulary]")


if __name__ == '__main__':
    main()
