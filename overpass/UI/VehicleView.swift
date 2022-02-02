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
        ZStack(alignment: .top) {
            Image("Ford_Mustang_Mach-E_4_2020_TOP_W_PORTRATE")
                .resizable()
                .scaledToFit()
            VStack {
                Spacer().frame(height: 60)
                BatteryIndicator(vehicleStore: vehicleStore)
                Spacer().frame(height: 50)
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

struct BatteryIndicator: View {
    @StateObject var vehicleStore : VehicleStore

    var body: some View {
        ZStack(alignment: .top) {
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 12.0, dash: [8]))
                .frame(width: 180, height: 200)
                .rotationEffect(Angle(degrees: -180))
            if let fill = vehicleStore.batteryFillLevel {
                Circle()
                    .trim(from: 0.0, to: fill/2)
                    .stroke(fillColor(), lineWidth: 12.0)
                    .frame(width: 180, height: 200)
                    .rotationEffect(Angle(degrees: -180))
            }
            // TODO use chargestations API to get charge target
            VStack() {
                Spacer().frame(height:20)
                if let fill = vehicleStore.batteryFillLevel {
                    Text("\(Int(fill*100))%")
                        .font(.custom("HelveticaNeue", size: 20.0))
                        .foregroundColor(.black)
                }
                Spacer().frame(height:10)
                if let gom = vehicleStore.kmToEmpty {
                    let miles = Measurement(value: gom, unit: UnitLength.kilometers).converted(to: UnitLength.miles)
                    Text("\(Int(miles.value)) \(miles.unit.symbol)")
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    fileprivate func fillColor() -> Color {
        if let bat = vehicleStore.batteryFillLevel {
            if bat < 0.10 {
                return Color.red
            }
            else if bat < 0.30 {
                return Color.yellow
            }
            else if bat < 0.50 {
                return Color.blue
            }
            else {
                return Color("Green")
            }
        }
        return Color.gray
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
        Group {
            VehicleView(vehicleStore: VehicleStore(true))
                .previewInterfaceOrientation(.portrait)
        }
    }
}
