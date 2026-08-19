import Combine
import Foundation
import StoreKit

enum Entitlement: String, CaseIterable, Identifiable {
    case premium

    var id: String { rawValue }
}

struct MonetizationState: Equatable {
    var availableEntitlements: Set<Entitlement> = []
    var premiumDisplayPrice: String?
    var isLoading = false
    var statusMessage: String?

    var hasPremium: Bool {
        availableEntitlements.contains(.premium)
    }
}

@MainActor
protocol MonetizationService: AnyObject {
    var currentState: MonetizationState { get }
    var statePublisher: AnyPublisher<MonetizationState, Never> { get }

    func start() async
    func refreshEntitlements() async
    func purchasePremium() async
    func restorePurchases() async
}

@MainActor
final class StoreKitMonetizationService: MonetizationService {
    nonisolated static let removeWatermarkProductID = "com.GregAdams.myjourney.removeWatermark"

    @Published private(set) var currentState: MonetizationState

    var statePublisher: AnyPublisher<MonetizationState, Never> {
        $currentState.eraseToAnyPublisher()
    }

    private var premiumProduct: Product?
    private var transactionUpdatesTask: Task<Void, Never>?
    private let debugPremiumOverride: Bool?

    init(debugPremiumOverride: Bool? = nil) {
        self.debugPremiumOverride = debugPremiumOverride
        self.currentState = MonetizationState(
            availableEntitlements: debugPremiumOverride == true ? [.premium] : [],
            premiumDisplayPrice: debugPremiumOverride == nil ? nil : "$1.99"
        )

        guard debugPremiumOverride == nil else {
            return
        }

        transactionUpdatesTask = Task { [weak self] in
            for await verificationResult in Transaction.updates {
                guard let self else { return }
                await self.handleTransactionUpdate(verificationResult)
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func start() async {
        guard debugPremiumOverride == nil else { return }

        currentState.isLoading = true
        defer { currentState.isLoading = false }

        do {
            premiumProduct = try await Product.products(for: [Self.removeWatermarkProductID]).first
            currentState.premiumDisplayPrice = premiumProduct?.displayPrice
            await updatePurchasedEntitlements()
        } catch {
            currentState.statusMessage = "The App Store is temporarily unavailable. Please try again."
        }
    }

    func refreshEntitlements() async {
        guard debugPremiumOverride == nil else { return }
        await updatePurchasedEntitlements()
    }

    func purchasePremium() async {
        guard debugPremiumOverride == nil else { return }

        if premiumProduct == nil {
            await start()
        }

        guard let premiumProduct else {
            currentState.statusMessage = "The Remove Watermark purchase is not available right now."
            return
        }

        currentState.isLoading = true
        currentState.statusMessage = nil
        defer { currentState.isLoading = false }

        do {
            switch try await premiumProduct.purchase() {
            case .success(let verificationResult):
                let transaction = try verified(verificationResult)
                await transaction.finish()
                await updatePurchasedEntitlements()
                currentState.statusMessage = "Watermark removed. Thank you for supporting My Journey."
            case .pending:
                currentState.statusMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                currentState.statusMessage = "The purchase could not be completed."
            }
        } catch {
            currentState.statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        guard debugPremiumOverride == nil else { return }

        currentState.isLoading = true
        currentState.statusMessage = nil
        defer { currentState.isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedEntitlements()
            currentState.statusMessage = currentState.hasPremium
                ? "Your Remove Watermark purchase has been restored."
                : "No previous Remove Watermark purchase was found."
        } catch {
            currentState.statusMessage = error.localizedDescription
        }
    }

    private func updatePurchasedEntitlements() async {
        var entitlements = Set<Entitlement>()

        for await verificationResult in Transaction.currentEntitlements {
            guard
                let transaction = try? verified(verificationResult),
                transaction.productID == Self.removeWatermarkProductID,
                transaction.revocationDate == nil
            else {
                continue
            }

            entitlements.insert(.premium)
        }

        currentState.availableEntitlements = entitlements
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        guard let transaction = try? verified(verificationResult) else {
            return
        }

        await updatePurchasedEntitlements()
        await transaction.finish()
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreKitVerificationError.failed
        }
    }
}

private enum StoreKitVerificationError: LocalizedError {
    case failed

    var errorDescription: String? {
        "The App Store could not verify this purchase."
    }
}
