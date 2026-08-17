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
            HStack(alignment: .center) {
                Text(verbatim: subtitle ?? "#\(entry.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    /// Outline icons with no visible box - the 8pt padding plus a 44x44
    /// minimum frame gives a full accessible tap target without drawing
    /// one, matching the header's plain-text look.
    private func iconButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("AccentColor"))
                .padding(8)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
