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
    @Environment(\.colorScheme) private var colorScheme
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

    /// A near-invisible tap-target backdrop for the star/share icons -
    /// visible enough to hint "this is tappable" without competing with
    /// the card's own background.
    private var iconBackdrop: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: subtitle ?? "#\(entry.id)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(displayText)
                .font(typography.fontDesign.font(size: typography.fontSize))
            HStack {
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
                Spacer()
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
        .padding(.vertical, 8)
    }

    private func iconButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("AccentColor"))
                .padding(8)
                .background(Circle().fill(iconBackdrop))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
