import SwiftUI

/// Presented from the share button: pick plain text, or one of the 10
/// postcard backgrounds. The fit check runs once (all backgrounds share the
/// same panel geometry) - if the hadith is too long to fit even at the
/// smallest font size, the background grid is replaced with a short
/// explanation instead of silently hiding the feature.
struct ShareOptionsSheet: View {
    let text: String
    let subtitle: String
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var isTextSharePresented = false

    private var fittingFontSize: CGFloat? {
        ShareCardFit.fittingFontSize(for: text, subtitle: subtitle)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        isTextSharePresented = true
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

                    if let fontSize = fittingFontSize {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                            ForEach(ShareCardBackground.allCases) { background in
                                NavigationLink(
                                    destination: ShareCardPreviewView(
                                        text: text, subtitle: subtitle, background: background, fontSize: fontSize
                                    )
                                ) {
                                    thumbnail(for: background)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "text.badge.xmark")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text(languageStore.strings.hadithTooLongForCard)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(languageStore.strings.shareCardTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isTextSharePresented) {
            ActivityShareSheet(items: [text])
        }
    }

    private func thumbnail(for background: ShareCardBackground) -> some View {
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
}
