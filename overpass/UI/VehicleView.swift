//
//  VehicleView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI

struct VehicleView: View {
    @StateObject var vehicleStore : VehicleStore
    var body: some View {
        ZStack {
            Image("Ford_Mustang_Mach-E_4_2020_TOP_W_PORTRATE")
                .resizable()
                .scaledToFit()
            VStack {
                BootStatus(vehicleStore: vehicleStore)
                Spacer().frame(height: 12.0)
                LockStatus(vehicleStore: vehicleStore)
            }
        }
        
        .onAppear {
            vehicleStore.startRefreshTask()
        }
        .onDisappear {
            vehicleStore.stopRefreshTask()
        }
    }
}

struct LockStatus: View {
    @StateObject var vehicleStore : VehicleStore
    var body: some View {
        if vehicleStore.vehicleStatus != nil {
            Button(action: toggleLock) {
                Text(lockStatus()).foregroundColor(lockColor())
            }
            .disabled(lockDisableStatus())
        }
    }
    
    fileprivate func toggleLock() {
        vehicleStore.toggleLock()
    }
    
    fileprivate func lockStatus() -> String {
        var status = "Unknown"
        switch (vehicleStore.lockState) {
        case .unlocked:
            status = "Unlocked"
        case .locked:
            status = "Locked"
        case .unlocking:
            status = "Unlocking"
        case .locking:
            status = "Locking"
        case .lockError:
            status = "Lock Error"
        case .unknown:
            status = "Unknown"
        }
        return status
    }
    
    fileprivate func lockDisableStatus() -> Bool {
        switch (vehicleStore.lockState) {
        case .unknown: fallthrough
        case .locking: fallthrough
        case .unlocking:
            return true
        default:
            return false
        }
    }
    
    fileprivate func lockColor() -> Color {
        var status = Color.blue
        if let lock = vehicleStore.vehicleStatus?.lockStatus?.value {
            if lock == "LOCKED" {
                status = Color.white
            }
            else {
                status = Color.orange
            }
        }
        return status
    }

}

struct BootStatus: View {
    @StateObject var vehicleStore : VehicleStore
    var body: some View {
        if vehicleStore.vehicleStatus != nil {
            Button(action: initiateRemoteStart) {
                Text(bootStatus()).foregroundColor(bootColor())
            }
            .disabled(startDisabledStatus())
        }
    }
    
    fileprivate func initiateRemoteStart() {
        vehicleStore.initiateRemoteStart()
    }
    
    fileprivate func bootStatus() -> String {
        var status = "Unknown"
        switch vehicleStore.remoteStartState {
        case .starting: status = "Starting"
        case .started: status = "Started"
        case .running: status = "Running"
        case .off: status = "Off"
        default: status = "Unknown"
        }
        return status
    }
    
    fileprivate func startDisabledStatus() -> Bool {
        switch vehicleStore.remoteStartState {
        case .running: return true
        default: return false
        }
    }
    
    fileprivate func bootColor() -> Color {
        var status = Color.white
        if let ignition = vehicleStore.vehicleStatus?.ignitionStatus?.value {
            switch ignition {
            case "Run": status = Color.green
            case "Off": status = Color.gray
            default:
                status = Color.white
            }
        }
        if let remote = vehicleStore.vehicleStatus?.remoteStartStatus?.value {
            if (remote == 1) {
                status = Color.blue
            }
        }
        return status
    }

}


struct VehicleView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleView(vehicleStore: VehicleStore(true))
.previewInterfaceOrientation(.portrait)
    }
}
