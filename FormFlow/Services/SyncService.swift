import Foundation
import Combine
import Network
import UIKit

// MARK: - Sync Service

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingOperations: Int = 0
    @Published var isOnline: Bool = true
    @Published var lastError: String?

    private var operationQueue: [SyncOperation] = []
    private var syncTimer: Timer?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.formflow.network-monitor")
    private let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

    private init() {
        loadQueueFromDisk()
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
        guard !operationQueue.isEmpty else {
            lastSyncDate = Date()
            return
        }

        isSyncing = true
        lastError = nil

        var failedOps: [SyncOperation] = []

        for var operation in operationQueue {
            do {
                try await pushOperation(operation)
                operation.synced = true
            } catch {
                operation.syncAttemptedAt = Date()
                operation.errorMessage = error.localizedDescription
                failedOps.append(operation)
            }
        }

        operationQueue = failedOps
        pendingOperations = failedOps.count
        lastSyncDate = Date()
        isSyncing = false

        if !failedOps.isEmpty {
            lastError = "Failed to sync \(failedOps.count) operation(s)"
        }

        saveQueueToDisk()
    }

    func queueOperation(type: SyncOperationType, entityType: String, entityId: UUID, fieldId: UUID? = nil, value: String? = nil) {
        let operation = SyncOperation(
            id: UUID(),
            type: type,
            entityType: entityType,
            entityId: entityId,
            fieldId: fieldId,
            value: value,
            timestamp: Date(),
            deviceId: deviceId,
            synced: false
        )
        operationQueue.append(operation)
        pendingOperations = operationQueue.count
        saveQueueToDisk()

        if isOnline {
            Task {
                await syncNow()
            }
        }
    }

    // MARK: - API Integration

    private func pushOperation(_ operation: SyncOperation) async throws {
        let _: SyncResponse = try await APIClient.shared.request(
            endpoint: "sync/operations",
            method: .post,
            body: operation
        )
    }

    // MARK: - Persistence

    private var queueFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pending_sync_queue.json")
    }

    private func saveQueueToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(operationQueue) else { return }
        try? data.write(to: queueFileURL, options: .atomic)
    }

    private func loadQueueFromDisk() {
        guard let data = try? Data(contentsOf: queueFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let ops = try? decoder.decode([SyncOperation].self, from: data) {
            operationQueue = ops
            pendingOperations = ops.count
        }
    }

    deinit {
        syncTimer?.invalidate()
        monitor.cancel()
    }
}

// MARK: - Sync Response

private struct SyncResponse: Decodable {
    let success: Bool
}
