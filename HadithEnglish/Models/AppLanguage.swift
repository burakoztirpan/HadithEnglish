import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, ar, tr
    case ind = "id"
    case urd = "ur"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .en: return "English"
        case .ar: return "العربية"
        case .tr: return "Türkçe"
        case .ind: return "Bahasa Indonesia"
        case .urd: return "اردو"
        }
    }

    var hadithResourceName: String {
        "hadith_\(rawValue)"
    }

    var isRightToLeft: Bool {
        self == .ar || self == .urd
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
    let appearanceLabel: String
    let appearanceSystem: String
    let appearanceLight: String
    let appearanceDark: String
    let dailyNotificationLabel: String
    let notificationTimeLabel: String
    let typographyLabel: String
    let fontLabel: String
    let fontSizeLabel: String
    let fontSerif: String
    let fontNewYork: String
    let fontPalatino: String
    let fontBaskerville: String
    let fontSans: String
    let fontAvenirNext: String
    let fontRounded: String
    let fontMonospaced: String
    let typographyPreviewText: String
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
    let hadithsSuffix: String
    let showMore: String
    let showLess: String
    let shareCardTitle: String
    let shareAsTextOption: String
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
                appearanceLabel: "Appearance",
                appearanceSystem: "System",
                appearanceLight: "Light",
                appearanceDark: "Dark",
                dailyNotificationLabel: "Daily Hadith Notification",
                notificationTimeLabel: "Notification Time",
                typographyLabel: "Typography",
                fontLabel: "Font",
                fontSizeLabel: "Font Size",
                fontSerif: "Serif",
                fontNewYork: "New York",
                fontPalatino: "Palatino",
                fontBaskerville: "Baskerville",
                fontSans: "Sans",
                fontAvenirNext: "Avenir Next",
                fontRounded: "Rounded",
                fontMonospaced: "Monospaced",
                typographyPreviewText: "Actions are judged by intentions.",
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
                todaysSelection: "Today's Selection",
                hadithsSuffix: "hadiths",
                showMore: "Show more",
                showLess: "Show less",
                shareCardTitle: "Share as Image",
                shareAsTextOption: "Share as Text"
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
                appearanceLabel: "المظهر",
                appearanceSystem: "النظام",
                appearanceLight: "فاتح",
                appearanceDark: "داكن",
                dailyNotificationLabel: "إشعار الحديث اليومي",
                notificationTimeLabel: "وقت الإشعار",
                typographyLabel: "الطباعة",
                fontLabel: "الخط",
                fontSizeLabel: "حجم الخط",
                fontSerif: "سيريف",
                fontNewYork: "New York",
                fontPalatino: "Palatino",
                fontBaskerville: "Baskerville",
                fontSans: "سانس",
                fontAvenirNext: "Avenir Next",
                fontRounded: "مدور",
                fontMonospaced: "أحادي المسافة",
                typographyPreviewText: "إنما الأعمال بالنيات.",
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
                todaysSelection: "مختارات اليوم",
                hadithsSuffix: "حديثًا",
                showMore: "عرض المزيد",
                showLess: "عرض أقل",
                shareCardTitle: "مشاركة كصورة",
                shareAsTextOption: "مشاركة كنص"
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
                appearanceLabel: "Görünüm",
                appearanceSystem: "Sistem",
                appearanceLight: "Açık",
                appearanceDark: "Koyu",
                dailyNotificationLabel: "Günlük Hadis Bildirimi",
                notificationTimeLabel: "Bildirim Saati",
                typographyLabel: "Tipografi",
                fontLabel: "Yazı Tipi",
                fontSizeLabel: "Yazı Boyutu",
                fontSerif: "Serif",
                fontNewYork: "New York",
                fontPalatino: "Palatino",
                fontBaskerville: "Baskerville",
                fontSans: "Sans",
                fontAvenirNext: "Avenir Next",
                fontRounded: "Yuvarlak",
                fontMonospaced: "Eş Aralıklı",
                typographyPreviewText: "Ameller niyetlere göredir.",
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
                todaysSelection: "Günün Seçkisi",
                hadithsSuffix: "hadis",
                showMore: "Devamını göster",
                showLess: "Daha az göster",
                shareCardTitle: "Görsel Olarak Paylaş",
                shareAsTextOption: "Metin Olarak Paylaş"
            )
        case .ind:
            return Strings(
                hadithSubjectsTitle: "Topik Hadis",
                searchSubjectsPrompt: "Cari topik",
                tabHadiths: "Hadis",
                tabFavorites: "Favorit",
                tabSetup: "Pengaturan",
                tabHome: "Beranda",
                favoritesTitle: "Favorit",
                noFavoritesYet: "Belum ada favorit",
                removeAction: "Hapus",
                rateOnAppStore: "Beri Nilai di App Store",
                shareThisApp: "Bagikan Aplikasi Ini",
                privacyPolicy: "Kebijakan Privasi",
                aboutSection: "Tentang",
                versionLabel: "Versi",
                setupTitle: "Pengaturan",
                languageLabel: "Bahasa",
                appearanceLabel: "Tampilan",
                appearanceSystem: "Sistem",
                appearanceLight: "Terang",
                appearanceDark: "Gelap",
                dailyNotificationLabel: "Notifikasi Hadis Harian",
                notificationTimeLabel: "Waktu Notifikasi",
                typographyLabel: "Tipografi",
                fontLabel: "Jenis Huruf",
                fontSizeLabel: "Ukuran Huruf",
                fontSerif: "Serif",
                fontNewYork: "New York",
                fontPalatino: "Palatino",
                fontBaskerville: "Baskerville",
                fontSans: "Sans",
                fontAvenirNext: "Avenir Next",
                fontRounded: "Rounded",
                fontMonospaced: "Monospace",
                typographyPreviewText: "Segala amal tergantung niatnya.",
                goodMorning: "Selamat Pagi",
                goodAfternoon: "Selamat Siang",
                goodEvening: "Selamat Malam",
                dayStreak: "Hari Beruntun",
                hadithOfTheDay: "Hadis Hari Ini",
                quickAccess: "Akses Cepat",
                randomHadith: "Hadis Acak",
                myFavorites: "Favorit Saya",
                continueReading: "Lanjutkan Membaca",
                searchHadith: "Cari Hadis",
                featuredTopics: "Topik Pilihan",
                todaysSelection: "Pilihan Hari Ini",
                hadithsSuffix: "hadis",
                showMore: "Tampilkan lebih banyak",
                showLess: "Tampilkan lebih sedikit",
                shareCardTitle: "Bagikan sebagai Gambar",
                shareAsTextOption: "Bagikan sebagai Teks"
            )
        case .urd:
            return Strings(
                hadithSubjectsTitle: "احادیث کے موضوعات",
                searchSubjectsPrompt: "موضوعات تلاش کریں",
                tabHadiths: "احادیث",
                tabFavorites: "پسندیدہ",
                tabSetup: "ترتیبات",
                tabHome: "ہوم",
                favoritesTitle: "پسندیدہ",
                noFavoritesYet: "ابھی تک کوئی پسندیدہ نہیں",
                removeAction: "ہٹائیں",
                rateOnAppStore: "App Store پر درجہ دیں",
                shareThisApp: "ایپ شیئر کریں",
                privacyPolicy: "پرائیویسی پالیسی",
                aboutSection: "کے بارے میں",
                versionLabel: "ورژن",
                setupTitle: "ترتیبات",
                languageLabel: "زبان",
                appearanceLabel: "ظاہری شکل",
                appearanceSystem: "سسٹم",
                appearanceLight: "ہلکا",
                appearanceDark: "گہرا",
                dailyNotificationLabel: "روزانہ حدیث اطلاع",
                notificationTimeLabel: "اطلاع کا وقت",
                typographyLabel: "ٹائپوگرافی",
                fontLabel: "فونٹ",
                fontSizeLabel: "فونٹ سائز",
                fontSerif: "سیرف",
                fontNewYork: "New York",
                fontPalatino: "Palatino",
                fontBaskerville: "Baskerville",
                fontSans: "سانس",
                fontAvenirNext: "Avenir Next",
                fontRounded: "گول",
                fontMonospaced: "یکساں فاصلہ",
                typographyPreviewText: "اعمال کا دارومدار نیتوں پر ہے۔",
                goodMorning: "صبح بخیر",
                goodAfternoon: "دن بخیر",
                goodEvening: "شام بخیر",
                dayStreak: "دن کا تسلسل",
                hadithOfTheDay: "آج کی حدیث",
                quickAccess: "فوری رسائی",
                randomHadith: "بے ترتیب حدیث",
                myFavorites: "میری پسندیدہ",
                continueReading: "پڑھنا جاری رکھیں",
                searchHadith: "حدیث تلاش کریں",
                featuredTopics: "نمایاں موضوعات",
                todaysSelection: "آج کا انتخاب",
                hadithsSuffix: "احادیث",
                showMore: "مزید دکھائیں",
                showLess: "کم دکھائیں",
                shareCardTitle: "تصویر کے طور پر شیئر کریں",
                shareAsTextOption: "متن کے طور پر شیئر کریں"
            )
        }
    }
}
