import SwiftUI

struct HadithCardView: View {
    let entry: HadithEntry
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var isSharePresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(entry.id)")
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
            Text(entry.trimmedText)
                .font(.system(.body, design: .serif))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color("CardBackground"))
    }
}
