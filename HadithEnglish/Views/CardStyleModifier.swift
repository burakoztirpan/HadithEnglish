import SwiftUI

extension View {
    /// Shared card treatment: soft shadow + hairline border, so cards read
    /// as raised surfaces against the cream background instead of sitting
    /// flush against it. Light mode uses real system Material (frosted-
    /// glass blur) tinted white, matching the app's other light-mode-only
    /// glass surfaces; dark mode keeps the flat CardBackground it always had.
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

private struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background {
                if colorScheme == .light {
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.white.opacity(0.35))
                    }
                } else {
                    Color("CardBackground")
                }
            }
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
