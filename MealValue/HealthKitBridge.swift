import Foundation
import HealthKit

// MARK: - HealthKitBridgeProtocol

protocol HealthKitBridgeProtocol {
    associatedtype AppModel
    associatedtype HKObjectType: HKObject

    static var hkIdentifier: String { get }
    static var hkUnit: HKUnit { get }

    static func toHealthKitSample(from model: AppModel, date: Date) -> HKObjectType?
    static func fromHealthKitSample(_ sample: HKObjectType) -> AppModel?
}

// MARK: - HealthKitWritable

protocol HealthKitWritable: HealthKitBridgeProtocol {
    static func write(_ model: AppModel, to manager: HealthKitManager) async throws
}

// MARK: - HealthKitReadable

protocol HealthKitReadable: HealthKitBridgeProtocol where HKObjectType == HKQuantitySample {
    static func query(from startDate: Date, to endDate: Date, limit: Int) -> HKSampleQuery
}

// MARK: - HealthKitError

enum HealthKitError: LocalizedError {
    case unavailable
    case typeNotFound(String)
    case notAuthorized
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "HealthKit is not available on this device."
        case .typeNotFound(let id):
            return "HealthKit type not found: \(id)"
        case .notAuthorized:
            return "HealthKit write authorization not granted."
        case .saveFailed(let underlying):
            return "HealthKit save failed: \(underlying.localizedDescription)"
        }
    }
}
