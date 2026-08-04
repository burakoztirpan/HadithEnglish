import SwiftUI

struct SettingsView: View {
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
                    Link("Rate on the App Store", destination: appStoreURL)
                    Button("Share this app") {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ActivityShareSheet(items: [appStoreURL])
                    }
                    Link("Privacy Policy", destination: privacyPolicyURL)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Setup")
        }
        .navigationViewStyle(.stack)
    }
}
