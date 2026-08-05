import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @EnvironmentObject private var typographyStore: TypographyStore

    private func appearanceName(_ theme: AppTheme) -> String {
        switch theme {
        case .system: return languageStore.strings.appearanceSystem
        case .light: return languageStore.strings.appearanceLight
        case .dark: return languageStore.strings.appearanceDark
        }
    }

    private func fontDesignName(_ design: HadithFontDesign) -> String {
        switch design {
        case .serif: return languageStore.strings.fontSerif
        case .newYork: return languageStore.strings.fontNewYork
        case .palatino: return languageStore.strings.fontPalatino
        case .baskerville: return languageStore.strings.fontBaskerville
        case .sans: return languageStore.strings.fontSans
        case .avenirNext: return languageStore.strings.fontAvenirNext
        case .rounded: return languageStore.strings.fontRounded
        case .monospaced: return languageStore.strings.fontMonospaced
        }
    }

    private let termsAndConditionsURL = URL(string: "https://burakoztirpan.online/hadiths-vault-terms-and-conditions")!
    // TODO: replace with the real App Store URL once known (this is a re-submission of an
    // existing 2019 listing, so check App Store Connect for the existing app URL).
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    @State private var isSharePresented = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker(languageStore.strings.languageLabel, selection: $languageStore.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.nativeName).tag(lang)
                        }
                    }
                    Picker(languageStore.strings.appearanceLabel, selection: $themeStore.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(appearanceName(theme)).tag(theme)
                        }
                    }
                }
                Section {
                    Toggle(languageStore.strings.dailyNotificationLabel, isOn: $notificationStore.isEnabled)
                    if notificationStore.isEnabled {
                        DatePicker(
                            languageStore.strings.notificationTimeLabel,
                            selection: $notificationStore.time,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                Section(languageStore.strings.typographyLabel) {
                    Text(languageStore.strings.typographyPreviewText)
                        .font(typographyStore.fontDesign.font(size: typographyStore.fontSize))
                        .padding(.vertical, 4)
                    Picker(languageStore.strings.fontLabel, selection: $typographyStore.fontDesign) {
                        ForEach(HadithFontDesign.allCases) { design in
                            Text(fontDesignName(design)).tag(design)
                        }
                    }
                    HStack {
                        Text(languageStore.strings.fontSizeLabel)
                        Slider(
                            value: $typographyStore.fontSize,
                            in: TypographyStore.minFontSize...TypographyStore.maxFontSize,
                            step: 1
                        )
                        Text(verbatim: "\(Int(typographyStore.fontSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                    }
                }
                Section {
                    Link(languageStore.strings.rateOnAppStore, destination: appStoreURL)
                    Button(languageStore.strings.shareThisApp) {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ActivityShareSheet(items: [appStoreURL])
                    }
                    Link(languageStore.strings.termsAndConditions, destination: termsAndConditionsURL)
                }
                Section(languageStore.strings.aboutSection) {
                    HStack {
                        Text(languageStore.strings.versionLabel)
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(languageStore.strings.setupTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
