import Foundation
import Combine
import Network

// MARK: - Sync Service

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingOperations: Int = 0
    @Published var isOnline: Bool = true

    private var syncTimer: Timer?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.formflow.network-monitor")

    private init() {
        startNetworkMonitoring()
        startPeriodicSync()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied {
                    await self?.syncNow()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncNow()
            }
        }
    }

    func syncNow() async {
        guard isOnline, !isSyncing else { return }
        isSyncing = true

        // Simulate sync
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        lastSyncDate = Date()
        pendingOperations = 0
        isSyncing = false
    }

    func queueOperation(type: SyncOperationType, entityType: String, entityId: UUID, fieldId: UUID? = nil, value: String? = nil) {
        pendingOperations += 1

        if isOnline {
            Task {
                await syncNow()
            }
        }
    }

    deinit {
        syncTimer?.invalidate()
        monitor.cancel()
    }
}
