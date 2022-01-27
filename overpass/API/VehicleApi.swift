//
//  APIService.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation
import KeychainSwift
import SwiftUI

class VehicleApi : RestApi {
    static let shared = VehicleApi()

    func getInfo() async throws {
        let data = try await makeFordRequest(string: "https://usapi.cv.ford.com/api/vehicles/v4/status?lrdt=01-01-1970%2000:00:00", retries: 1)
        print ("--- getInfo = \(String(data: data, encoding:.utf8)!)")
    }
    
    func getVehicleStatus(vin: String) async throws -> VehicleStatusMessage {
        let data = try await makeFordRequest(string: "https://usapi.cv.ford.com/api/vehicles/v4/\(vin)/status?lrdt=01-01-1970%2000:00:00")
        print ("VehicleStatus = \(String(data: data, encoding:.utf8)!)")
        let message = try jsonDecoder().decode(VehicleStatusMessage.self, from: data)
        if let status = message.status {
            if status == 200 {
                return message
            }
            throw RestError.statusError(status: status, data)
        }
        return message
    }
    
    func getVehicleInfo(vin: String) async throws -> VehicleInfo {
        let data = try await makeFordRequest(string: "https://usapi.cv.ford.com/api/users/vehicles/\(vin)/detail?lrdt=01-01-1970%2000:00:00")
        print ("VehicleInfo = \(String(data: data, encoding:.utf8)!)")
        return try jsonDecoder().decode(VehicleInfo.self, from: data)
    }
}
