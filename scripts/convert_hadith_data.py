import json

SOURCE_DIR = "/private/tmp/claude-501/-Users-burakmacminim4-Desktop-habiproof-property-inspection/15a8c5d6-4ff9-485d-99f8-306bfd61eba9/scratchpad/hadith-source"
OUTPUT_MAP = {
    "eng": "HadithEnglish/hadith_en.json",
    "ara": "HadithEnglish/hadith_ar.json",
    "tur": "HadithEnglish/hadith_tr.json",
}

# Book titles are only translated in the English edition's metadata; every
# edition uses the same English titles as a stable reference (matches how
# sunnah.com and similar apps present chapter names regardless of the
# hadith translation language).
titles = json.load(open(f"{SOURCE_DIR}/eng-bukhari.json"))["metadata"]["sections"]

for source_lang, out_path in OUTPUT_MAP.items():
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
        {"name": titles[str(book_num)], "hadiths": entries}
        for book_num, entries in sorted(books.items())
    ]

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(subjects, f, ensure_ascii=False, indent=2)

    total_hadiths = sum(len(s["hadiths"]) for s in subjects)
    print(f"{out_path}: {len(subjects)} subjects, {total_hadiths} hadiths")
