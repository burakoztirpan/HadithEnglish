import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
        }
        .font(.subheadline.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.85), in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}

struct ToastOverlayModifier: ViewModifier {
    @EnvironmentObject private var toastCenter: ToastCenter

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = toastCenter.message {
                ToastView(message: message)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastCenter.message)
            }
        }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}
