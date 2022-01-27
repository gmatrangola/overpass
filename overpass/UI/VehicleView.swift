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
            vehicleStore.startRefresTimer()
        }
        .onDisappear {
            vehicleStore.stopRefreshTimer()
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
        }
    }
    
    fileprivate func toggleLock() {
        // TODO Lock/unlock commands
    }
    
    fileprivate func lockStatus() -> String {
        var status = "Unknown"
        if let lock = vehicleStore.vehicleStatus?.lockStatus?.value {
            if lock == "LOCKED" {
                status = "Locked"
            }
            else {
                status = "Unlocked"
            }
        }
        return status
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
            Text(bootStatus()).foregroundColor(bootColor())
        }
    }
    fileprivate func bootStatus() -> String {
        var status = "Unknown"
        if let ignition = vehicleStore.vehicleStatus?.ignitionStatus?.value {
            switch ignition {
            case "Run": status = "Running"
            case "Off": status = "Off"
            default:
                status = "---"
            }
        }
        if let remote = vehicleStore.vehicleStatus?.remoteStartStatus?.value {
            if (remote == 1) {
                status = "R/S"
            }
        }
        return status
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
