import SwiftUI

/// Presented from the share button: pick plain text, or one of the 10
/// postcard backgrounds to render the hadith onto before handing off to the
/// system share sheet.
struct ShareOptionsSheet: View {
    let text: String
    let subtitle: String
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var shareItems: [Any]?

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Hadith Vault"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        shareItems = [text]
                    } label: {
                        HStack {
                            Image(systemName: "text.alignleft")
                            Text(languageStore.strings.shareAsTextOption)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                        ForEach(ShareCardBackground.allCases) { background in
                            Button {
                                shareItems = renderedImage(for: background)
                            } label: {
                                Group {
                                    if let uiImage = background.uiImage {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(9.0 / 16.0, contentMode: .fill)
                                    } else {
                                        Color.black
                                    }
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(languageStore.strings.shareCardTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
            ActivityShareSheet(items: shareItems ?? [])
        }
    }

    private func renderedImage(for background: ShareCardBackground) -> [Any] {
        guard let image = ShareCardRenderer.render(
            text: text,
            subtitle: subtitle,
            background: background,
            appName: appName
        ) else { return [text] }
        return [image]
    }
}
