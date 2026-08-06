import SwiftUI

/// Full-size preview of the rendered card before it's actually shared -
/// picking a background used to jump straight to the OS share sheet with no
/// chance to see the result first.
struct ShareCardPreviewView: View {
    let text: String
    let subtitle: String
    let background: ShareCardBackground
    let fontSize: CGFloat
    let onShared: () -> Void
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var isActivityPresented = false

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Hadith Vault"
    }

    private var renderedImage: UIImage? {
        ShareCardRenderer.render(text: text, subtitle: subtitle, background: background, appName: appName, fontSize: fontSize)
    }

    var body: some View {
        VStack(spacing: 16) {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                Button {
                    isActivityPresented = true
                } label: {
                    Label(languageStore.strings.shareAction, systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .sheet(isPresented: $isActivityPresented) {
                    ActivityShareSheet(items: [image]) { completed in
                        if completed {
                            onShared()
                        }
                    }
                }
            } else {
                Spacer()
                Text(languageStore.strings.hadithTooLongForCard)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
