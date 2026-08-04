import json

SOURCE_DIR = "/private/tmp/claude-501/-Users-burakmacminim4-Desktop-habiproof-property-inspection/15a8c5d6-4ff9-485d-99f8-306bfd61eba9/scratchpad/hadith-source"
OUTPUT_MAP = {
    "eng": ("en", "HadithEnglish/hadith_en.json"),
    "ara": ("ar", "HadithEnglish/hadith_ar.json"),
    "tur": ("tr", "HadithEnglish/hadith_tr.json"),
}

# Per-language book titles, verified against both fawazahmed0/hadith-api's own
# English section names (exact match, all 97) and Ikhan/sahih-bukhari-english
# for Arabic (exact match, all 97). Turkish titles are original translations
# using standard Turkish Islamic terminology, following the same style as the
# English titles (short term, with a parenthetical Arabic/Turkish loanword
# where the English does the same).
book_titles = json.load(open("scripts/book_titles.json"))

for source_lang, (title_lang, out_path) in OUTPUT_MAP.items():
    data = json.load(open(f"{SOURCE_DIR}/{source_lang}-bukhari.json"))

    books = {}
    for h in data["hadiths"]:
        book_num = h["reference"]["book"]
        if book_num == 0:
            continue  # scattered variant-chain hadiths, no coherent chapter
        if not isinstance(h["hadithnumber"], int):
            continue  # inserted sub-narrations like "402.2", not a whole id
        books.setdefault(book_num, []).append(
            {"id": h["hadithnumber"], "hadith": h["text"]}
        )

    subjects = [
        {"bookNumber": book_num, "name": book_titles[str(book_num)][title_lang], "hadiths": entries}
        for book_num, entries in sorted(books.items())
    ]

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(subjects, f, ensure_ascii=False, indent=2)

    total_hadiths = sum(len(s["hadiths"]) for s in subjects)
    print(f"{out_path}: {len(subjects)} subjects, {total_hadiths} hadiths")
