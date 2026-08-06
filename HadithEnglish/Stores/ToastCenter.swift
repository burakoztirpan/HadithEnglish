import Foundation

/// A brief, self-dismissing status message (e.g. "Shared") shown above
/// whatever screen is on top - including right as a sheet dismisses back to
/// it. Lives at the app root so it isn't clipped by a List row's bounds the
/// way an overlay on a deeply-nested view would be.
final class ToastCenter: ObservableObject {
    @Published private(set) var message: String?

    private var dismissWorkItem: DispatchWorkItem?

    func show(_ message: String, duration: TimeInterval = 2) {
        dismissWorkItem?.cancel()
        self.message = message

        let workItem = DispatchWorkItem { [weak self] in
            self?.message = nil
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}
