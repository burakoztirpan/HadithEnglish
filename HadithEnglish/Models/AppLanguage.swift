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
                favoritesTitle: "Favorites",
                noFavoritesYet: "No favorites yet",
                removeAction: "Remove",
                rateOnAppStore: "Rate on the App Store",
                shareThisApp: "Share this app",
                privacyPolicy: "Privacy Policy",
                aboutSection: "About",
                versionLabel: "Version",
                setupTitle: "Setup",
                languageLabel: "Language"
            )
        case .ar:
            return Strings(
                hadithSubjectsTitle: "مواضيع الأحاديث",
                searchSubjectsPrompt: "البحث في المواضيع",
                tabHadiths: "الأحاديث",
                tabFavorites: "المفضلة",
                tabSetup: "الإعدادات",
                favoritesTitle: "المفضلة",
                noFavoritesYet: "لا توجد مفضلات بعد",
                removeAction: "إزالة",
                rateOnAppStore: "قيّم التطبيق في App Store",
                shareThisApp: "شارك التطبيق",
                privacyPolicy: "سياسة الخصوصية",
                aboutSection: "حول",
                versionLabel: "الإصدار",
                setupTitle: "الإعدادات",
                languageLabel: "اللغة"
            )
        case .tr:
            return Strings(
                hadithSubjectsTitle: "Hadis Konuları",
                searchSubjectsPrompt: "Konularda ara",
                tabHadiths: "Hadisler",
                tabFavorites: "Favoriler",
                tabSetup: "Ayarlar",
                favoritesTitle: "Favoriler",
                noFavoritesYet: "Henüz favori yok",
                removeAction: "Kaldır",
                rateOnAppStore: "App Store'da Değerlendir",
                shareThisApp: "Uygulamayı Paylaş",
                privacyPolicy: "Gizlilik Politikası",
                aboutSection: "Hakkında",
                versionLabel: "Sürüm",
                setupTitle: "Ayarlar",
                languageLabel: "Dil"
            )
        }
    }
}
