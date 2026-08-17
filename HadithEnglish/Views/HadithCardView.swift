import SwiftUI

struct HadithCardView: View {
    let entry: HadithEntry
    var subtitle: String? = nil
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var typography: TypographyStore
    @EnvironmentObject private var toastCenter: ToastCenter
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var reviewPromptManager: ReviewPromptManager
    @State private var isSharePresented = false
    @State private var isExpanded = false

    private static let previewCharacterLimit = 280

    private var isLong: Bool {
        entry.trimmedText.count > Self.previewCharacterLimit
    }

    private var displayText: String {
        guard isLong, !isExpanded else { return entry.trimmedText }
        return entry.trimmedText.prefix(Self.previewCharacterLimit) + "…"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                header
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    iconButton(
                        systemName: favorites.isFavorite(entry.id) ? "star.fill" : "star",
                        accessibilityLabel: favorites.isFavorite(entry.id)
                            ? languageStore.strings.removeFromFavoritesLabel
                            : languageStore.strings.addToFavoritesLabel
                    ) {
                        let wasAdded = !favorites.isFavorite(entry.id)
                        favorites.toggle(entry.id)
                        if wasAdded {
                            reviewPromptManager.favoriteAdded(
                                uniqueFavoritesCount: favorites.favoriteIDs.count,
                                adManager: adManager
                            )
                        }
                    }
                    iconButton(systemName: "square.and.arrow.up", accessibilityLabel: languageStore.strings.shareAction) {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ShareOptionsSheet(text: entry.trimmedText, subtitle: subtitle ?? "#\(entry.id)") {
                            isSharePresented = false
                            toastCenter.show(languageStore.strings.sharedConfirmation)
                        }
                    }
                }
            }
            Text(displayText)
                .font(typography.fontDesign.font(size: typography.fontSize))
            if isLong {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? languageStore.strings.showLess : languageStore.strings.showMore)
                        .font(.caption).bold()
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    /// A named category reads as the card's identity, so it keeps normal
    /// caption weight; a bare reference number is a citation mark, not a
    /// heading, so it drops a size and dims further - the same distinction
    /// the app already draws for numerals in Today's Selection.
    @ViewBuilder
    private var header: some View {
        if let subtitle {
            Text(verbatim: subtitle)
                .font(.caption)
                .foregroundColor(Color("SubtleText"))
        } else {
            Text(verbatim: "#\(entry.id)")
                .font(.caption2)
                .foregroundColor(Color("SubtleText").opacity(0.7))
                .monospacedDigit()
        }
    }

    /// Matches the accent-tinted icon capsule already used for category
    /// icons elsewhere in the app (SubjectsListView), instead of either a
    /// bare glyph or a neutral-gray smudge. The capsule itself stays a
    /// compact 32pt; the surrounding 44x44 frame keeps the tap target
    /// accessible without visually inflating the chip.
    private func iconButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color("AccentColor").opacity(0.1)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
    }
}
