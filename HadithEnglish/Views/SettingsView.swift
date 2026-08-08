import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var notificationStore: NotificationStore
    @EnvironmentObject private var typographyStore: TypographyStore
    @EnvironmentObject private var removeAdsStore: RemoveAdsStore
    @EnvironmentObject private var toastCenter: ToastCenter
    @EnvironmentObject private var consentManager: ConsentManager

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

    private let termsAndConditionsURL = URL(string: "https://burakoztirpan.online/hadith-vault-terms-and-conditions")!
    private let privacyPolicyURL = URL(string: "https://burakoztirpan.online/hadith-valut-privacy-policy")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private var removeAdsButtonLabel: String {
        if let price = removeAdsStore.product?.displayPrice {
            return "\(languageStore.strings.removeAdsButtonTitle) – \(price)"
        }
        return languageStore.strings.removeAdsButtonTitle
    }

    private func purchaseRemoveAds() async {
        removeAdsStore.errorMessage = nil
        await removeAdsStore.purchase()
        if removeAdsStore.isPurchased {
            toastCenter.show(languageStore.strings.removeAdsToastMessage)
        } else if let error = removeAdsStore.errorMessage {
            toastCenter.show(error)
        }
    }

    private func restorePurchases() async {
        removeAdsStore.errorMessage = nil
        await removeAdsStore.restore()
        if removeAdsStore.isPurchased {
            toastCenter.show(languageStore.strings.removeAdsToastMessage)
        } else if let error = removeAdsStore.errorMessage {
            toastCenter.show(error)
        }
    }

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
                Section {
                    if removeAdsStore.isPurchased {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentColor"))
                            Text(languageStore.strings.removeAdsPurchasedLabel)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageStore.strings.removeAdsDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button {
                                Task { await purchaseRemoveAds() }
                            } label: {
                                if removeAdsStore.isPurchasing {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text(removeAdsButtonLabel)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(removeAdsStore.product == nil || removeAdsStore.isPurchasing)
                        }
                        .padding(.vertical, 4)
                    }
                    // Always visible regardless of purchase state - App Store
                    // Review Guideline 3.1.1 requires a discoverable restore
                    // mechanism; hiding it once "purchased" is a documented,
                    // common rejection reason.
                    Button(languageStore.strings.restorePurchasesButtonTitle) {
                        Task { await restorePurchases() }
                    }
                } header: {
                    Text(languageStore.strings.removeAdsTitle)
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
                    // Rate/Share rows removed for now - both need a real App Store Connect
                    // app ID, which doesn't exist yet. Re-add once that ID is known.
                    Link(languageStore.strings.termsAndConditions, destination: termsAndConditionsURL)
                    Link(languageStore.strings.privacyPolicy, destination: privacyPolicyURL)
                    if consentManager.isPrivacyOptionsRequired {
                        Button(languageStore.strings.privacyOptionsButtonTitle) {
                            consentManager.presentPrivacyOptionsForm { error in
                                if let error {
                                    toastCenter.show(error.localizedDescription)
                                }
                            }
                        }
                    }
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
