import Foundation
import StoreKit

/// Single source of truth for the "Remove Ads" one-time purchase.
/// `isPurchased` becoming true is what every ad surface in the app checks
/// before doing anything - see HadithDetailView, which is the only other
/// file that reads this store.
@MainActor
final class RemoveAdsStore: ObservableObject {
    static let productID = "com.hadithvault.adfree"

    @Published private(set) var isPurchased = false
    @Published private(set) var product: Product?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Catches purchases/renewals that complete outside a direct
        // purchase() call on this device (e.g. Ask to Buy approval,
        // or a purchase made on another device syncing in).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        // StoreKit 2's own cryptographic signature check is the only
        // trust boundary here - .unverified results are treated as not
        // purchased, never as a fallback "probably fine."
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.productID {
            isPurchased = true
        }
        await transaction.finish()
    }
}
