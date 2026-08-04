import Foundation

/// SF Symbol per Sahih Bukhari book number (1...97). Every name here is
/// verified against the SF Symbols availability database to exist by iOS 15,
/// this project's deployment target - an unverified name silently renders as
/// a broken/missing glyph instead of failing to build.
enum BookIcons {
    static let icons: [Int: String] = [
        1: "sparkles",                 // Revelation
        2: "heart.fill",               // Belief
        3: "book.fill",                // Knowledge
        4: "drop.fill",                // Ablutions (Wudu')
        5: "drop.fill",                // Bathing (Ghusl)
        6: "drop.fill",                // Menstrual Periods
        7: "wind",                     // Tayammum
        8: "hands.sparkles.fill",      // Prayers (Salat)
        9: "clock.fill",               // Times of the Prayers
        10: "speaker.wave.2.fill",     // Call to Prayers (Adhaan)
        11: "calendar",                // Friday Prayer
        12: "exclamationmark.triangle.fill", // Fear Prayer
        13: "gift.fill",               // The Two Festivals (Eids)
        14: "moon.stars.fill",         // Witr Prayer
        15: "cloud.rain.fill",         // Invoking Allah for Rain
        16: "moon.fill",               // Eclipses
        17: "book.closed.fill",        // Prostration During Recital of Qur'an
        18: "figure.walk",             // Shortening the Prayers
        19: "moon.stars.fill",         // Prayer at Night (Tahajjud)
        20: "building.columns.fill",   // Virtues of Prayer at Masjid Makkah/Madinah
        21: "figure.walk",             // Actions while Praying
        22: "exclamationmark.circle.fill", // Forgetfulness in Prayer
        23: "leaf.fill",               // Funerals
        24: "dollarsign.circle.fill",  // Zakat
        25: "airplane",                // Hajj
        26: "airplane",                // Umrah
        27: "exclamationmark.triangle.fill", // Pilgrims Prevented
        28: "pawprint.fill",           // Penalty of Hunting
        29: "building.columns.fill",   // Virtues of Madinah
        30: "moon.fill",               // Fasting
        31: "moon.stars.fill",         // Taraweeh
        32: "sparkles",                // Night of Qadr
        33: "building.columns.fill",   // I'tikaf
        34: "cart.fill",               // Sales and Trade
        35: "cart.fill",               // Salam Sale
        36: "house.fill",              // Shuf'a
        37: "briefcase.fill",          // Hiring
        38: "creditcard.fill",         // Debt Transfer
        39: "shield.fill",             // Kafalah
        40: "person.2.fill",           // Representation/Proxy
        41: "leaf.fill",               // Agriculture
        42: "drop.fill",               // Distribution of Water
        43: "creditcard.fill",         // Loans/Bankruptcy
        44: "text.bubble.fill",        // Khusoomaat
        45: "magnifyingglass",         // Lost Things (Luqatah)
        46: "exclamationmark.triangle.fill", // Oppressions
        47: "person.2.fill",           // Partnership
        48: "key.fill",                // Mortgaging
        49: "person.fill",             // Manumission of Slaves
        50: "doc.text.fill",           // Makaatib
        51: "gift.fill",               // Gifts
        52: "eye.fill",                // Witnesses
        53: "checkmark.seal.fill",     // Peacemaking
        54: "doc.text.fill",           // Conditions
        55: "doc.text.fill",           // Wills and Testaments
        56: "shield.fill",             // Jihad
        57: "dollarsign.circle.fill",  // Khumus
        58: "doc.text.fill",           // Jizyah and Treaties
        59: "sparkles",                // Beginning of Creation
        60: "star.fill",               // Prophets
        61: "star.fill",               // Virtues of the Prophet and Companions
        62: "person.3.fill",           // Companions
        63: "person.3.fill",           // Ansar
        64: "flag.fill",               // Military Expeditions (Maghazi)
        65: "book.fill",               // Tafsir
        66: "book.closed.fill",        // Virtues of the Qur'an
        67: "heart.fill",              // Marriage (Nikah)
        68: "doc.text.fill",           // Divorce
        69: "person.3.fill",           // Supporting the Family
        70: "fork.knife",              // Food, Meals
        71: "gift.fill",               // Aqiqa
        72: "pawprint.fill",           // Hunting, Slaughtering
        73: "flame.fill",              // Al-Adha Sacrifice
        74: "cup.and.saucer.fill",     // Drinks
        75: "bed.double.fill",         // Patients
        76: "stethoscope",             // Medicine
        77: "tshirt.fill",             // Dress
        78: "hands.sparkles.fill",     // Good Manners and Form
        79: "hand.raised.fill",        // Asking Permission
        80: "text.bubble.fill",        // Invocations
        81: "heart.fill",              // Ar-Riqaq (heart tenderness)
        82: "sparkles",                // Divine Will (Qadar)
        83: "checkmark.seal.fill",     // Oaths and Vows
        84: "checkmark.circle.fill",   // Expiation for Unfulfilled Oaths
        85: "scalemass.fill",          // Inheritance (Faraid)
        86: "scalemass.fill",          // Hudood (Punishments)
        87: "dollarsign.circle.fill",  // Blood Money (Diyat)
        88: "exclamationmark.triangle.fill", // Apostates
        89: "exclamationmark.triangle.fill", // Coercion
        90: "theatermasks.fill",       // Tricks
        91: "moon.zzz.fill",           // Interpretation of Dreams
        92: "exclamationmark.triangle.fill", // Afflictions and End of the World
        93: "scalemass.fill",          // Judgments (Ahkaam)
        94: "sparkles",                // Wishes
        95: "checkmark.seal.fill",     // Accepting Info from a Truthful Person
        96: "book.closed.fill",        // Holding Fast to the Qur'an and Sunnah
        97: "infinity",                // Oneness of Allah (Tawheed)
    ]
}
