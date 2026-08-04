import SwiftUI

struct HadithCardView: View {
    let entry: HadithEntry
    var subtitle: String? = nil
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var typography: TypographyStore
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
            HStack {
                Text(verbatim: subtitle ?? "#\(entry.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    favorites.toggle(entry.id)
                } label: {
                    Image(systemName: favorites.isFavorite(entry.id) ? "star.fill" : "star")
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(.plain)
                Button {
                    isSharePresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color("AccentColor"))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isSharePresented) {
                    ActivityShareSheet(items: [entry.trimmedText])
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
}
