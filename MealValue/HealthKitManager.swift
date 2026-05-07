import Foundation
import HealthKit

// MARK: - HealthKitManager

@MainActor final class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published private(set) var isAuthorized = false

    private init() {}

    // MARK: - Availability

    func isHealthDataAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization(
        toShare shareTypes: Set<HKSampleType>,
        read readTypes: Set<HKObjectType>
    ) async throws {
        guard isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        isAuthorized = true
    }

    func authorizationStatus(for identifier: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return .notDetermined
        }
        return store.authorizationStatus(for: type)
    }

    // MARK: - Write

    func save(_ object: HKObject) async throws {
        do {
            try await store.save(object)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }

    func save(_ objects: [HKObject]) async throws {
        do {
            try await store.save(objects)
        } catch {
            throw HealthKitError.saveFailed(error)
        }
    }

    // MARK: - Query

    func execute(_ query: HKQuery) {
        store.execute(query)
    }

    func stop(_ query: HKQuery) {
        store.stop(query)
    }
}
