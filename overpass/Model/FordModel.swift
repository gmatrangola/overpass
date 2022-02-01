//
//  FordModel.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/17/22.
//

import Foundation

enum RestError : Error {
    case httpError(status: Int, _ body: Data? = nil)
    case statusError(status: Int, _ body: Data)
    case responseError(status: Int?, _ description: String)
}

struct VehicleStatusError : Codable {
    var Sid: String
    var status: Int
    var version: String
}

struct InfoStatusError : Codable {
    var statusContext: String
    var statusCode: String
    var message: String
}

struct VehicleInfoError : Codable {
    var httpStatus: Int
    var status: Int
    var requestStatus: String
    var error: InfoStatusError
    var time: Date
    var version: String
}

struct Status: Codable {
    var value: String?
    var status: String?
    var timestamp: Date?
}

struct IntStatus: Codable {
    var value: Int?
    var status: String?
    var timestamp: Date?
}

struct DoubleStatus: Codable {
    var value: Double?
    var status: String?
    var timestamp: Date?
}

struct BoolStatus: Codable {
    var value: Bool?
    var status: String?
    var timestamp: Date?
}

struct StringOrDouble: Codable {
    var value: Double?
    
    init(from decoder: Decoder) throws {
        if let double = try? decoder.singleValueContainer().decode(Double.self) {
            value = double
            return
        }
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            value = Double(string)
            return
        }
        print("Unknown StringOrDouble \(try decoder.singleValueContainer().codingPath)")
        throw Error.couldNotFindStringOrDouble
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    enum Error: Swift.Error {
        case couldNotFindStringOrDouble
    }
}

struct Gps: Codable {
    var latitude: StringOrDouble?
    var longitude: StringOrDouble?
    var gpsState: String?
    var status: String?
    var timestamp: Date?
}

struct RemoteStart: Codable {
    var remoteStartDuration: Int?
    var remoteStartTime: Int?
    var status: String?
    var timestamp: Date?
}

struct BatteryHealth: Codable {
    var batteryHealth: Status?
    var batteryStatusActual: IntStatus?
}

struct OilStatus: Codable {
    var oilLife: String?
    var oilLifeActual: Int?
    var status: String?
    var timestamp: Date?
}

struct TirePressureManagementSytem: Codable {
    var tirePressureByLocation: IntStatus?
    var tirePressureSystemStatus: Status?
    var dualRearWheel: IntStatus?
    var leftFrontTireStatus: Status?
    var leftFrontTirePressure: Status?
    var rightFrontTireStatus: Status?
    var rightFrontTirePressure: Status?
    var outerLeftRearTireStatus: Status?
    var outerLeftRearTirePressure: Status?
    var outerRightRearTireStatus: Status?
    var outerRightRearTirePressure: Status?
    var innerLeftRearTireStatus: Status?
    var innerLeftRearTirePressure: Status?
    var innerRightRearTireStatus: Status?
    var innerRightRearTirePressure: Status?
    var recommendedFrontTirePressure: IntStatus?
    var recommendedRearTirePressure: IntStatus?
}

struct CcsStatus: Codable {
    var timestamp: Date?
    var location: Int?
    var vehicleConnectivity: Int?
    var vehicleData: Int?
    var drivingCharacteristics: Int?
    var contacts: Int?
}

struct VehicleStatusMessage: Codable {
    var status: Int?
    var vehiclestatus: VehicleStatus?
    var version: String?
}

struct DcFastChargeData: Codable {
    var fstChrgBulkTEst: Status?
    var fstChrgCmpltTEst: Status?
}

struct DoorStatus: Codable {
    var driverDoor: Status?
    var hoodDoor: Status?
    var innerTailgateDoor: Status?
    var leftRearDoor: Status?
    var passengerDoor: Status?
    var rightReerDoor: Status?
    var tailgateDoor: Status?
}

struct WindowPosition: Codable {
    var driverWindowPosition: Status?
    var passWindowPosition: Status?
    var rearDriverWindowPos: Status?
    var rearPassWindowPos: Status?
}

struct VehicleStatus : Codable {
    var vin :  String?
    var PrmtAlarmEvent: Status?
    var lockStatus: Status?
    var alarm: Status?
    var battTracLoSocDisplay: Status?
    var odometer: DoubleStatus?
    var fuel: String?
    var gps: Gps?
    var remoteStart: RemoteStart?
    var remoteStartStatus: IntStatus?
    var battery: BatteryHealth?
    var batteryChargeStatus: Status?
    var batteryFillLevel: DoubleStatus?
    var batteryPerfStatus: Status?
    var batteryTracLowChargeThreshold: Status?
    var chargeEndTime: Status?
    var chargeStartTime: Status?
    var chargePowerType: String?
    var chargingStatus: Status?
    var dcFastChargeData: DcFastChargeData?
    var oil: OilStatus?
    var tirePressure: Status?
    var authorization: String?
    var TPMS: TirePressureManagementSytem?
    var firmwareUpgInProgress: BoolStatus?
    var deepSleepInProgress: BoolStatus?
    var ccsSettings: CcsStatus?
    var dieselSystemStatus: String?
    var doorStatus: DoorStatus?
    var elVehDTE: DoubleStatus?
    var hybridModeStatus: Status?
    var ignitionStatus: Status?
    var lastModifiedDate: Date?
    var lastRefresh: Date?
    var outandAbout: Status?
    var plugStatus: IntStatus?
    var preCondStatusDsply: Status?
    var serverTime: Date?
    var windowPosition: WindowPosition?
}

struct Vehicle : Codable {
    var assignedDealer: String?
    var averageMiles: String?
    var bodyStyle: String?
    var brandCode: String?
    var color: String?
    var configurationId: String?
    var cylinders: String?
    var drivetrain: String?
    var drivingConditionId: String?
    var engineDisp: String?
    var estimatedMilage: String?
    var fuelType: String?
    var hasAuthorizedUser: Int?
    var headUnitType: String?
    var latestMilage: String?
    var licenseplate: String?
    var lifeStyleXML: String?
    var make: String?
    var mileage: String?
    var mileageDate: Date?
    var mileageSource: String?
    var modelCode: String?
    var modelName: String?
    var modelYear: String?
    var ngSdnManaged: Int?
    var nickName: String?
    var ownerCycle: String?
    var ownerindicator: String?
    var preferredDealer: String?
    var primaryIndicator: String?
    var productVariant: String?
    var purchaseDate: String?
    var registrationDate: String?
    var sellingDealer: String?
    var series: String?
    var steeringWheelType: String?
    var syncVehicleIndicator: String?
    var tcuEnabled: Int?
    var transmission: String?
    var vehicleAuthorizationIndicator: Int?
    var vehicleImageId: String?
    var vehicleRole: String?
    var vehicleType: String?
    var vehicleUpdateDate: String?
    var versionDescription: String?
    var vhrNotificationDate: String?
    var vhrNotificationStatus: String?
    var vhrReadyDate: String?
    var vhrReadyIndicator: String?
    var vhrStatus: String?
    var vhrUrgentNotificationStatus: String?
    var vin: String?
    var warrantyStartDate: String?
}

struct VehicleInfo : Codable {
    var status: Int?
    var vehicle: Vehicle?
    var version: String?
}

struct VehicleData : Codable {
    var vin: String?
    var vehicleInfo: VehicleInfo?
    var latestStatus: VehicleStatus?
}

struct CommandResponse: Codable {
    // text: "{"$id":"1","commandId":"d7ed1677-6258-4390-8178-cf853259489e","status":200,"version":"1.0.0"}"
    var commandId: String?
    var status: Int?
    var version: String?
}

struct LockCommandStatus: Codable {
    // {"$id":"1","remoteLockFailureReasons":null,"eventData":{"$id":"2","warning":0,"DoorPresenceWarning":0,"DoorStatuses":{"$id":"3","$values":[]},"DoorPresentStatuses":{"$id":"4","$values":[]}},"errorDetailCode":null,"status":200,"version":"3.0.0"}
    var remoteLockFailureReasons: String?
    var errorDetailCode: String?
    var status: Int?
    var version: String?

    private enum CodingKeys: String, CodingKey {
        case remoteLockFailureReasons, errorDetailCode, status, version
    }
}

struct RemoteStartStatus: Codable {
    //  {"$id":"1","remoteStartFailures":null,"DoorPresenceWarning":0,"DoorPresentStatuses":{"$id":"2","$values":[]},"errorDetailCode":null,"status":200,"version":"4.0.0"}
    var remoteStartFailures: String?
    var errorDetailCode: String?
    var status: Int?
    var version: String?

    private enum CodingKeys: String, CodingKey {
        case remoteStartFailures, errorDetailCode, status, version
    }
}
