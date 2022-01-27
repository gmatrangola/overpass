//
//  VehicleStore.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/24/22.
//

import Foundation
import SwiftUI

@MainActor
class VehicleStore : ObservableObject {
    @Published var vins: [String] = []
    @Published var currentVin: String?
    @Published var vehicleStatus: VehicleStatus?
    @Published var vehicleInfo: VehicleInfo?
    private var refreshTimer : Timer?
    
    init(_ debug: Bool = false) {
        if (!debug) {
            let defaults = UserDefaults.standard
            currentVin = defaults.string(forKey: "currentVin") ?? ""
            readData()
        }
        else {
            vins = ["123123123"]
            currentVin = "123123123"
            vehicleStatus = VehicleStatus()
            vehicleStatus?.lockStatus = Status(value: "LOCKED")
            vehicleStatus?.remoteStartStatus = IntStatus(value: 0)
            vehicleStatus?.ignitionStatus = Status(value: "Off")
        }
    }
    
    func addVin(vin: String) {
        if !vins.contains(vin) {
            vins.append(vin)
            let defaults = UserDefaults.standard
            defaults.set(vins, forKey: "vins")
        }
    }
    
    func storeCurrentVin() {
        let defaults = UserDefaults.standard
        defaults.set(currentVin, forKey: "currentVin")
    }
    
    func removeVin(vin: String) {
        vins.removeAll(where: {$0 == vin})
        let defaults = UserDefaults.standard
        defaults.set(vins, forKey: "vins")
    }

    fileprivate func updateVehicleData(_ vin: String) {
        Task {
            do {
                let defaults = UserDefaults.standard
                let vehicleStatusMessage = try await VehicleApi.shared.getVehicleStatus(vin: vin)
                let jsonEncoder = JSONEncoder()
                if let vstatus = vehicleStatusMessage.vehiclestatus {
                    vehicleStatus = vstatus
                    defaults.set(try jsonEncoder.encode(vstatus), forKey: "status-" + vin)
                }
                vehicleInfo = try await VehicleApi.shared.getVehicleInfo(vin: vin)
                defaults.set(try jsonEncoder.encode(vehicleInfo), forKey: "info-" + vin)
            }
            catch {
                print ("Error getting vehicle data \(error)")
                Thread.callStackSymbols.forEach{print($0)}
            }
        }
    }
    
    fileprivate func readVehicleData(_ vin: String) {
        let defaults = UserDefaults.standard
        let jsonDecoder = JSONDecoder()
        let vsjson = defaults.object(forKey: "status-" + vin) as? Data
        if let vsjsonData = vsjson {
            do {
                vehicleStatus = try jsonDecoder.decode(VehicleStatus.self, from: vsjsonData)
            }
            catch {
                print("Error: \(error) decoding \(String(data: vsjsonData, encoding:.utf8)!)")
            }
        }
        let vijson = defaults.object(forKey: "info-" + vin) as? Data
        if let vijsonData = vijson {
            do {
                vehicleInfo = try jsonDecoder.decode(VehicleInfo.self, from: vijsonData)
            }
            catch {
                print("Error: \(error) decoding VehicleInformation JSON \(String(data: vijsonData, encoding:.utf8)!)")
            }
        }
        // overrite properties and storage with latest from REST API
    }
    
    func startRefresTimer() {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        refreshTimer?.tolerance = 2.0
    }
    
    func stopRefreshTimer() {
        if let timer = refreshTimer {
            timer.invalidate()
            refreshTimer = nil
        }
    }
    
    @objc func refresh() {
        print("refresh")
        if let vin = currentVin {
            readVehicleData(vin)
            updateVehicleData(vin)
        }
    }
    
    fileprivate func readData() {
        let defaults = UserDefaults.standard
        vins = defaults.object(forKey: "vins") as? [String] ?? [String]()
        if currentVin == nil || currentVin!.isEmpty && !vins.isEmpty {
            currentVin = vins[0]
            storeCurrentVin()
        }
        if let vin = currentVin {
            readVehicleData(vin)
            updateVehicleData(vin)
        }
    }
}
