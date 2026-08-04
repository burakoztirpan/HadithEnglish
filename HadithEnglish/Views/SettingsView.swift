import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    // TODO: replace with the real privacy policy URL before submitting to App Store Connect.
    private let privacyPolicyURL = URL(string: "https://example.com/hadithenglish/privacy")!
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
                }
                Section {
                    Link(languageStore.strings.rateOnAppStore, destination: appStoreURL)
                    Button(languageStore.strings.shareThisApp) {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ActivityShareSheet(items: [appStoreURL])
                    }
                    Link(languageStore.strings.privacyPolicy, destination: privacyPolicyURL)
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
        }
        .navigationViewStyle(.stack)
    }
}
