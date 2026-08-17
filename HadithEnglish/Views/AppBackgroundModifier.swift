import SwiftUI

extension View {
    /// The shared screen background: a subtle top-to-bottom cream wash in
    /// light mode, so Material/blur cards and buttons layered on top have
    /// something to actually blur - a perfectly flat color behind a glass
    /// surface just reads as the same flat color, no glass effect at all.
    /// Dark mode stays flat (unchanged from its existing look).
    func appScreenBackground() -> some View {
        modifier(AppScreenBackgroundModifier())
    }
}

private struct AppScreenBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background(background.ignoresSafeArea())
    }

    @ViewBuilder
    private var background: some View {
        if colorScheme == .light {
            LinearGradient(
                colors: [Color("AppBackground"), Color("AppBackgroundGradientEnd")],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Color("AppBackground")
        }
    }
}
