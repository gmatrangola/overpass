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
    @Published var currentState: CurrentState?
    @Published var vins: [String] = []
    @Published var currentVin: String?
    @Published var vehicleStatus: VehicleStatus?
    @Published var vehicleInfo: VehicleInfo?
    @Published var lockState: LockState = .unknown
    @Published var remoteStartState: RemoteStartState = .unknown
    @Published var batteryFillLevel: Double? // percentage
    @Published var kmToEmpty: Double? // GOM
    
    private var refreshTask: Task<Void, Never>?
    private var commandPollTask: Task<Void, Never>?
    
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
            lockState = .locked
            remoteStartState = .off
            currentState = CurrentState.savedStatus(Date())
            batteryFillLevel = 0.544
            kmToEmpty = 155
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

    fileprivate func updateVehicleData(_ vin: String) async {
        do {
            let defaults = UserDefaults.standard
            let vehicleStatusMessage = try await VehicleApi.shared.getVehicleStatus(vin: vin)
            let jsonEncoder = JSONEncoder()
            if let vstatus = vehicleStatusMessage.vehiclestatus {
                vehicleStatus = vstatus
                defaults.set(try jsonEncoder.encode(vstatus), forKey: "status-" + vin)
                let date = vehicleStatus?.lastRefresh ?? Date()
                currentState = .savedStatus(date) // TODO Store date received

                vehicleStatusUpdated()
            }
            // TODO do this less often
            vehicleInfo = try await VehicleApi.shared.getVehicleInfo(vin: vin)
            defaults.set(try jsonEncoder.encode(vehicleInfo), forKey: "info-" + vin)
        }
        catch {
            print ("Error getting vehicle data \(error)")
            Thread.callStackSymbols.forEach{print($0)}
        }
    }
    
    fileprivate func readVehicleData(_ vin: String) {
        let defaults = UserDefaults.standard
        let jsonDecoder = JSONDecoder()
        let vsjson = defaults.object(forKey: "status-" + vin) as? Data
        if let vsjsonData = vsjson {
            do {
                vehicleStatus = try jsonDecoder.decode(VehicleStatus.self, from: vsjsonData)
                let date = vehicleStatus?.lastRefresh ?? Date()
                currentState = .savedStatus(date) // TODO Store date received
                vehicleStatusUpdated()
            }
            catch {
                print("Error: \(error) decoding \(String(data: vsjsonData, encoding:.utf8)!)")
                currentState = .unkownError(error.localizedDescription)
            }
        }
        let vijson = defaults.object(forKey: "info-" + vin) as? Data
        if let vijsonData = vijson {
            do {
                vehicleInfo = try jsonDecoder.decode(VehicleInfo.self, from: vijsonData)
            }
            catch {
                print("Error: \(error) decoding VehicleInformation JSON \(String(data: vijsonData, encoding:.utf8)!)")
                currentState = .unkownError(error.localizedDescription)
            }
        }
        // overrite properties and storage with latest from REST API
    }
    
    fileprivate func vehicleStatusUpdated() {
        switch (vehicleStatus?.lockStatus?.value) {
            case "LOCKED" : lockState = .locked
            case "UNLOCKED" : lockState = .unlocked
            default: lockState = .unknown
        }
        switch (vehicleStatus?.remoteStartStatus?.value) {
            case 1: remoteStartState = .started(vehicleStatus?.remoteStart?.remoteStartTime)
            case 0: remoteStartState = .off
            default: remoteStartState = .off
        }
        if let level = vehicleStatus?.batteryFillLevel?.value {
            batteryFillLevel = level / 100.0 // because it's a %
        }
        kmToEmpty = vehicleStatus?.elVehDTE?.value
    }

    func toggleLock() {
        Task {
            if let vin = currentVin {
                do {
                    let commandId = try await troggleLock(vin)
                    if let id = commandId {
                        startCommandPoll(id, 3, "door/lock")
                    }
                }
                catch {
                    print("toggleLock Error \(error)")
                    currentState = CurrentState.unkownError(error.localizedDescription)
                }
            }
        }
    }
    
    fileprivate func troggleLock(_ vin: String) async throws -> String? {
        stopRefreshTask()
        switch(lockState) {
        case .locked: fallthrough
        case .locking:
            lockState = .unlocking
            let response = try await VehicleApi.shared.unlock(vin: vin)
            if response.status != nil && response.status == 200 {
                currentState = CurrentState.locking
                return response.commandId
            }
            else {
                throw RestError.responseError(status: response.status, "Lock Error")
            }
        case .unlocked: fallthrough
        case .unlocking:
            lockState = .locking
            let response = try await VehicleApi.shared.lock(vin: vin)
            if response.status != nil && response.status == 200 {
                currentState = CurrentState.unlocking
                return response.commandId
            }
            else {
                throw RestError.responseError(status: response.status, "Unlock Error")
            }
        default:
            throw StateError.lockError("Invalid lock state \(lockState)")
        }
    }
    
    func initiateRemoteStart() {
        Task {
            if let vin = currentVin {
                do {
                    let remoteStartId = try await remoteStart(vin)
                    if let id = remoteStartId {
                        startCommandPoll(id, 4, "einge/start")
                    }
                }
            }
        }
    }
    
    func remoteStart(_ vin: String) async throws -> String? {
        stopRefreshTask()
        switch(remoteStartState) {
        case .starting: fallthrough
        case .started:
            remoteStartState = .off
            let response = try await VehicleApi.shared.remoteStartCancel(vin: vin)
            if response.status != nil && response.status == 200 {
                currentState = CurrentState.ready
                return response.commandId
            }
            else {
                throw RestError.responseError(status: response.status, "Start Error")
            }
        case .off:
            remoteStartState = .starting
            let response = try await VehicleApi.shared.remoteStart(vin: vin)
            if response.status != nil && response.status == 200 {
                currentState = CurrentState.ready
                return response.commandId
            }
            else {
                throw RestError.responseError(status: response.status, "Start Error")
            }
        default:
            throw StateError.lockError("Invalid Remote Start state \(remoteStartState)")
        }
    }
        
    
    fileprivate func startCommandPoll(_ id: String, _ version: Int, _ type: String) {
        stopRefreshTask()
        commandPollTask = Task {
            if let vin = currentVin {
                var retry = 5
                while (retry > 0) {
                    print ("startCommandPoll \(retry) \(id) V\(version) \(type)")
                    do {
                        let response = try await VehicleApi.shared.getCommandStatus(vin: vin, version: version, commandId: id, type: type)
                        if response.status == 200 {
                            currentState = .ready
                            break
                        }
                        else {
                            try await Task.sleep(nanoseconds: 1_000_000_000 * 15)
                            retry -= 1
                        }
                    }
                    catch {
                        currentState = .restError(error.localizedDescription)
                        break
                    }
                }
                startRefreshTask()
            }
        }
    }
    
    fileprivate func stopCommandPoll() {
        commandPollTask?.cancel()
        startRefreshTask()
    }
        
    func startRefreshTask() {
        stopRefreshTask()
        refreshTask = Task {
            while !Task.isCancelled {
                print("refresh")
                do {
                    if let vin = currentVin {
                        readVehicleData(vin)
                        await updateVehicleData(vin)
                    }
                    try await Task.sleep(nanoseconds: 1_000_000_000 * 15)
                }
                catch {
                    print ("refresh failed \(error)")
                    currentState = .unkownError(error.localizedDescription)
                }
            }
            refreshTask = nil
        }
    }
    
    func stopRefreshTask() {
        refreshTask?.cancel()
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
            Task {
                await updateVehicleData(vin)
            }
        }
    }
}
