import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, ar, tr

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .en: return "English"
        case .ar: return "العربية"
        case .tr: return "Türkçe"
        }
    }

    var hadithResourceName: String {
        "hadith_\(rawValue)"
    }

    var isRightToLeft: Bool {
        self == .ar
    }
}

struct Strings {
    let hadithSubjectsTitle: String
    let searchSubjectsPrompt: String
    let tabHadiths: String
    let tabFavorites: String
    let tabSetup: String
    let tabHome: String
    let favoritesTitle: String
    let noFavoritesYet: String
    let removeAction: String
    let rateOnAppStore: String
    let shareThisApp: String
    let privacyPolicy: String
    let aboutSection: String
    let versionLabel: String
    let setupTitle: String
    let languageLabel: String
    let goodMorning: String
    let goodAfternoon: String
    let goodEvening: String
    let dayStreak: String
    let hadithOfTheDay: String
    let quickAccess: String
    let randomHadith: String
    let myFavorites: String
    let continueReading: String
    let searchHadith: String
    let featuredTopics: String
    let todaysSelection: String
}

extension AppLanguage {
    var strings: Strings {
        switch self {
        case .en:
            return Strings(
                hadithSubjectsTitle: "Hadith Subjects",
                searchSubjectsPrompt: "Search subjects",
                tabHadiths: "Hadiths",
                tabFavorites: "Favorites",
                tabSetup: "Setup",
                tabHome: "Home",
                favoritesTitle: "Favorites",
                noFavoritesYet: "No favorites yet",
                removeAction: "Remove",
                rateOnAppStore: "Rate on the App Store",
                shareThisApp: "Share this app",
                privacyPolicy: "Privacy Policy",
                aboutSection: "About",
                versionLabel: "Version",
                setupTitle: "Setup",
                languageLabel: "Language",
                goodMorning: "Good Morning",
                goodAfternoon: "Good Afternoon",
                goodEvening: "Good Evening",
                dayStreak: "Day Streak",
                hadithOfTheDay: "Hadith of the Day",
                quickAccess: "Quick Access",
                randomHadith: "Random Hadith",
                myFavorites: "My Favorites",
                continueReading: "Continue Reading",
                searchHadith: "Search Hadith",
                featuredTopics: "Featured Topics",
                todaysSelection: "Today's Selection"
            )
        case .ar:
            return Strings(
                hadithSubjectsTitle: "مواضيع الأحاديث",
                searchSubjectsPrompt: "البحث في المواضيع",
                tabHadiths: "الأحاديث",
                tabFavorites: "المفضلة",
                tabSetup: "الإعدادات",
                tabHome: "الرئيسية",
                favoritesTitle: "المفضلة",
                noFavoritesYet: "لا توجد مفضلات بعد",
                removeAction: "إزالة",
                rateOnAppStore: "قيّم التطبيق في App Store",
                shareThisApp: "شارك التطبيق",
                privacyPolicy: "سياسة الخصوصية",
                aboutSection: "حول",
                versionLabel: "الإصدار",
                setupTitle: "الإعدادات",
                languageLabel: "اللغة",
                goodMorning: "صباح الخير",
                goodAfternoon: "طاب يومك",
                goodEvening: "مساء الخير",
                dayStreak: "أيام متتالية",
                hadithOfTheDay: "حديث اليوم",
                quickAccess: "الوصول السريع",
                randomHadith: "حديث عشوائي",
                myFavorites: "مفضلتي",
                continueReading: "متابعة القراءة",
                searchHadith: "البحث عن حديث",
                featuredTopics: "مواضيع مميزة",
                todaysSelection: "مختارات اليوم"
            )
        case .tr:
            return Strings(
                hadithSubjectsTitle: "Hadis Konuları",
                searchSubjectsPrompt: "Konularda ara",
                tabHadiths: "Hadisler",
                tabFavorites: "Favoriler",
                tabSetup: "Ayarlar",
                tabHome: "Ana Sayfa",
                favoritesTitle: "Favoriler",
                noFavoritesYet: "Henüz favori yok",
                removeAction: "Kaldır",
                rateOnAppStore: "App Store'da Değerlendir",
                shareThisApp: "Uygulamayı Paylaş",
                privacyPolicy: "Gizlilik Politikası",
                aboutSection: "Hakkında",
                versionLabel: "Sürüm",
                setupTitle: "Ayarlar",
                languageLabel: "Dil",
                goodMorning: "Günaydın",
                goodAfternoon: "İyi Günler",
                goodEvening: "İyi Akşamlar",
                dayStreak: "Günlük Seri",
                hadithOfTheDay: "Günün Hadisi",
                quickAccess: "Hızlı Erişim",
                randomHadith: "Rastgele Hadis",
                myFavorites: "Favorilerim",
                continueReading: "Kaldığım Yer",
                searchHadith: "Hadis Ara",
                featuredTopics: "Öne Çıkan Konular",
                todaysSelection: "Günün Seçkisi"
            )
        }
    }
}
