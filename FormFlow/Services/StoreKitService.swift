import Foundation
import StoreKit

// MARK: - StoreKit 2 Service

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var currentSubscription: Product?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let productIDs: Set<String> = [
        "formflow.pro.monthly",
        "formflow.pro.annual",
        "formflow.business.monthly",
        "formflow.business.annual"
    ]

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                isLoading = false
                return transaction

            case .userCancelled:
                isLoading = false
                return nil

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval."
                return nil

            @unknown default:
                isLoading = false
                return nil
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        try? await AppStore.sync()
        await updatePurchasedProducts()
        isLoading = false
    }

    // MARK: - Check Entitlements

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        var activeSubscription: Product?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)

                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                }
            }
        }

        purchasedProductIDs = purchased
        currentSubscription = activeSubscription
    }

    // MARK: - Plan Helpers

    var currentPlan: SubscriptionPlan {
        if purchasedProductIDs.contains("formflow.business.monthly") ||
           purchasedProductIDs.contains("formflow.business.annual") {
            return .businessMonthly
        }
        if purchasedProductIDs.contains("formflow.pro.monthly") ||
           purchasedProductIDs.contains("formflow.pro.annual") {
            return .proMonthly
        }
        return .free
    }

    func canAccess(feature: PaidFeature) -> Bool {
        switch feature {
        case .pdfExport, .auditExport, .unlimitedTemplates, .unlimitedWorkflows:
            return currentPlan != .free
        case .multiSite, .customBranding, .unlimitedUsers:
            return currentPlan == .businessMonthly || currentPlan == .businessAnnual
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard case .verified(let transaction) = result else {
                        print("[FormFlow] Unverified transaction received, skipping")
                        continue
                    }
                    await self?.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("[FormFlow] Transaction listener error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Types

enum PaidFeature {
    case pdfExport
    case auditExport
    case unlimitedTemplates
    case unlimitedWorkflows
    case multiSite
    case customBranding
    case unlimitedUsers
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed."
        }
    }
}
