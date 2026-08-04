import json
import re
import zlib

SOURCE_DIR = "/private/tmp/claude-501/-Users-burakmacminim4-Desktop-habiproof-property-inspection/15a8c5d6-4ff9-485d-99f8-306bfd61eba9/scratchpad/hadith-source"
# .zlib output: raw JSON compresses ~76% (measured: 22.1MB -> 5.3MB across all
# three languages) since hadith text is highly redundant natural language.
# Despite the name, Apple's Compression framework NSDataCompressionAlgorithmZlib
# decodes raw DEFLATE (RFC 1951, no header/trailer) - NOT the zlib-wrapped
# format (RFC 1950) zlib.compress() produces by default. wbits=-15 below opts
# into raw deflate output to match; verified round-trip against the actual
# NSData decompression call, not just assumed from the name.
OUTPUT_MAP = {
    "eng": ("en", "HadithEnglish/hadith_en.json.zlib"),
    "ara": ("ar", "HadithEnglish/hadith_ar.json.zlib"),
    "tur": ("tr", "HadithEnglish/hadith_tr.json.zlib"),
}

# Per-language book titles, verified against both fawazahmed0/hadith-api's own
# English section names (exact match, all 97) and Ikhan/sahih-bukhari-english
# for Arabic (exact match, all 97). Turkish titles are original translations
# using standard Turkish Islamic terminology, following the same style as the
# English titles (short term, with a parenthetical Arabic/Turkish loanword
# where the English does the same).
book_titles = json.load(open("scripts/book_titles.json"))

# The Turkish source appends scholarly cross-reference apparatus after
# "Tekrar:" ("Repeat:") and several equivalent phrasings - hadith numbers /
# other-book citations, not part of the actual narration. In most cases
# (source data issue, not introduced by this script) whatever was supposed
# to follow is missing entirely, so the text visibly cuts off mid-thought:
# "...dedim. Tekrar:". Only the bare dangling case (nothing real after the
# marker) is trimmed - it's safe because the narration is already a
# complete sentence before the marker starts. Cases with real citation
# content after are left alone: some embed a genuine continuation (e.g.
# "Tekrar: 3315 [-1827-] İbn Ömer r.a. ..."), so blindly stripping
# everything after the marker would occasionally cut real content, not
# just apparatus.
#
# First pass only matched the exact string "Tekrar:", catching 743 of 981
# occurrences. Spot-checking wider (user-reported example, unrelated hadith)
# turned up typos and phrasing variants the exact match missed: "Tekrarı:",
# "Tektar:", "Tekra:", "Tekrar yerler:", "Hadisin geçtiği diğer yer(ler):",
# "N nolu Hadisin geçtiği diğer yer(ler):", "Diğer tahric(edenler):" - all
# the same underlying pattern (a citation-list intro with nothing after),
# just worded differently. NUMBER_TAIL strips trailing citation number
# lists first (e.g. "2539, 2607, 3131") so a trailing phrase can be found
# underneath them; the loop repeats since these markers can nest/repeat
# ("1543 nolu Hadisin geçtiği diğer yerler: 1686; 1544 nolu ...").
NUMBER_TAIL = re.compile(r"[\s,;.]*\d+[\s,;.]*\Z")
# "1544 nolu" ("numbered 1544") - a repeated reference-block prefix left
# dangling when the whole block it introduces got stripped (e.g. two
# apparatus blocks back to back: "...yerler: 1686; 1544 nolu Hadisin
# geçtiği diğer yerler:" - stripping the second phrase leaves "1544 nolu").
NUMBERED_TAIL = re.compile(r"[\s,;.]*\d+\s+nolu\s*\Z", re.IGNORECASE)
DANGLING_APPARATUS_PHRASES = [
    "hadisin geçtiği diğer yerler",
    "hadisin geçtiği diğer yer",
    "nolu hadisin geçtiği diğer yerler",
    "nolu hadisin geçtiği diğer yer",
    "in geçtiği diğer yerler",
    "in geçtiği diğer yer",
    "nun geçtiği diğer yerler",
    "nun geçtiği diğer yer",
    "hadisin tekrarı",
    "diğer tahric edenler",
    "diğer tahric",
    "tekrar yerler",
    "tekrarı",
    "tekrar",
    "tektar",
    "tekra",
]


def strip_dangling_apparatus(text: str) -> str:
    original = text.rstrip()
    if not original.endswith(":"):
        return text  # only ever touch text that dangles on a bare colon
    t = original
    found_phrase = False
    changed = True
    while changed:
        changed = False
        if t.endswith(":"):
            t = t[:-1].rstrip()
            changed = True
        number_match = NUMBER_TAIL.search(t)
        if number_match:
            t = t[: number_match.start()].rstrip(" ,;.")
            changed = True
        numbered_match = NUMBERED_TAIL.search(t)
        if numbered_match:
            t = t[: numbered_match.start()].rstrip(" ,;.")
            changed = True
        lowered = t.lower()
        for phrase in DANGLING_APPARATUS_PHRASES:
            if lowered.endswith(phrase):
                t = t[: len(t) - len(phrase)].rstrip(" ,;.")
                changed = True
                found_phrase = True
                break
    # Only commit the change if a real apparatus phrase was matched - a bare
    # trailing colon with no recognizable apparatus marker (e.g. a genuine
    # narrative gap like "...ve şöyle de:" where a quote is simply missing
    # from the source) is left untouched rather than silently hiding the
    # colon, which wouldn't actually fix anything.
    return t if found_phrase else text

# The Turkish source was clearly scraped from a paginated website: 69
# hadiths (manually reviewed all of them, plus 981 more caught by the
# separate Tekrar: handling below) contain leftover UI text - "click here"
# CTAs ("İZAHI İÇİN BURAYA TIKLA"), pagination markers ("BİR SONRAKİ SAYFA"
# - next page), volume boundaries ("CİLT BURADA SONA ERDİ"), and Bukhari's
# own chapter/"Bab" heading titles bleeding into the hadith body. None of
# this is part of the narration itself, and it always appears as a suffix
# (confirmed: real narration never resumes after one of these markers).
#
# First pass tried matching runs of 3+ consecutive ALL-CAPS words and
# removing just the matched span. That missed cases where the junk is
# interrupted by numbers or embedded Arabic ("İZAH'I 38. SAYFADA GEÇTİ"),
# which breaks up a "run" into fragments too short to match. Fixed by
# instead searching for known trigger words directly (order-independent of
# case-run length), then truncating from the *start* of the earliest
# trigger to the end of the string - not just removing the matched text.
#
# The remaining problem: a naive "cut back to the last '.' before the
# trigger" sometimes lands on a period *inside* another junk fragment
# (e.g. "...kılmıştır." [end of real text] "KİTABU'Z-ZEKAT BİTTİ." [junk
# sentence, also ends in a period] "...BİR SONRAKİ SAYFA" [trigger]) -
# naively that finds "BİTTİ." and stops too late, leaving junk in. Fixed
# by walking backward through sentence-end candidates and only accepting
# one whose preceding word contains a lowercase letter - real Turkish
# narration always ends on a normal (non-caps) word, so this reliably
# distinguishes the true boundary from a junk-internal period.
UI_TRIGGER = re.compile(
    r"TIKLA\w*|\bSAYFA\b|\bCİLT\b|BÖLÜM\w*|GÖREBİLİRSİNİZ|BAB VE HAD|HADİS(?:LER)? VAR"
)
# Catch-all for anything not in the specific trigger list above: a run of 3+
# ALL-CAPS words that continues all the way to the end of the string (e.g.
# a stray trailing "SALLALLAHU ALEYHİ VE SELLEM" honorific fragment found
# during spot-checking, not matched by any named trigger). Anchored to the
# end specifically so it can't misfire on a legitimate caps word appearing
# mid-sentence.
CAPS_WORD = r"[A-ZİŞĞÜÖÇ][A-ZİŞĞÜÖÇ']*"
TRAILING_CAPS_RUN = re.compile(rf"(?:{CAPS_WORD}\s+){{2,}}{CAPS_WORD}\Z")
SENTENCE_END = re.compile(r"[.!?][\"'”]?\s")
WORD_BEFORE_END = re.compile(r"(\w+)[.!?][\"'”]?\s*\Z")


def strip_scraped_ui_text(text: str) -> str:
    candidates = [m.start() for m in [UI_TRIGGER.search(text), TRAILING_CAPS_RUN.search(text)] if m]
    if not candidates:
        return text
    cut_start = min(candidates)
    before = text[:cut_start]
    for end in reversed(list(SENTENCE_END.finditer(before))):
        candidate = before[: end.end()]
        word_match = WORD_BEFORE_END.search(candidate)
        if word_match and any(c.islower() for c in word_match.group(1)):
            return candidate.rstrip()
    return text  # no safe cut point found; leave untouched rather than guess

for source_lang, (title_lang, out_path) in OUTPUT_MAP.items():
    data = json.load(open(f"{SOURCE_DIR}/{source_lang}-bukhari.json"))

    books = {}
    for h in data["hadiths"]:
        book_num = h["reference"]["book"]
        if book_num == 0:
            continue  # scattered variant-chain hadiths, no coherent chapter
        if not isinstance(h["hadithnumber"], int):
            continue  # inserted sub-narrations like "402.2", not a whole id
        text = h["text"]
        if title_lang == "tr":
            text = strip_scraped_ui_text(text)
            text = strip_dangling_apparatus(text)
        if not text.strip():
            continue  # source has zero text for this id in this language (46 in
            # Turkish, 4 each in English/Arabic) - a blank hadith card is worse
            # than a missing one, and there's nothing to reconstruct
        books.setdefault(book_num, []).append(
            {"id": h["hadithnumber"], "hadith": text}
        )

    subjects = [
        {"bookNumber": book_num, "name": book_titles[str(book_num)][title_lang], "hadiths": entries}
        for book_num, entries in sorted(books.items())
    ]

    raw = json.dumps(subjects, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    compressed = compressor.compress(raw) + compressor.flush()
    with open(out_path, "wb") as f:
        f.write(compressed)

    total_hadiths = sum(len(s["hadiths"]) for s in subjects)
    print(f"{out_path}: {len(subjects)} subjects, {total_hadiths} hadiths, "
          f"{len(raw)} -> {len(compressed)} bytes ({100*len(compressed)//len(raw)}%)")
