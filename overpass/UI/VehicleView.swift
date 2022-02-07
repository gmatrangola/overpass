//
//  VehicleView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI

struct VehicleView: View {
    @StateObject var vehicleStore : VehicleService
    var body: some View {
        ZStack(alignment: .top) {
            Image("Ford_Mustang_Mach-E_4_2020_TOP_W_PORTRATE")
                .resizable()
                .scaledToFit()
                .frame(alignment: .topLeading)
            VStack(alignment: .subCentre ) {
                Spacer().frame(height: 60)
                HStack {
                    PlugStatusView(vehicleStore: vehicleStore)
                    Spacer().frame(width: 15.0)
                    BatteryIndicator(vehicleStore: vehicleStore)
                        .alignmentGuide(.subCentre) { d in d.width/2 }
                }
                Spacer().frame(height: 80)
                BootStatus(vehicleStore: vehicleStore)
                Spacer().frame(height: 12.0)
                LockStatus(vehicleStore: vehicleStore)
                GeometryReader { geometry in EmptyView() }
            }
            .alignmentGuide(.subCentre) { d in d.width/2}
        }
        .frame(maxWidth: .infinity)
        
        .onAppear {
            vehicleStore.startRefreshTask()
        }
        .onDisappear {
            vehicleStore.stopRefreshTask()
        }
    }
}

//Custom Alignment Guide
extension HorizontalAlignment {
    enum SubCenter: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[HorizontalAlignment.center]
        }
    }

    static let subCentre = HorizontalAlignment(SubCenter.self)
}

struct PlugStatusView: View {
    @StateObject var vehicleStore : VehicleService

    var body: some View {
        if vehicleStore.plugState == .pluggedIn {
            HStack(spacing: 1.0) {
                switch vehicleStore.chargeState {
                case .chargeScheduled:
                    Image(systemName: "bolt.badge.a").foregroundColor(Color.gray)
                case .chargeTargetReached:
                    Spacer()
                case .forceCharge:
                    Image(systemName: "bolt.circle").foregroundColor(Color.yellow)
                case .acCharge:
                    Image(systemName: "bolt").foregroundColor(Color.yellow)
                case .level3Charging:
                    Image(systemName: "bolt.fill").foregroundColor(Color.yellow)
                default:
                    Image(systemName: "bolt").foregroundColor(Color.gray)
                }
                Image(systemName: "powerplug")
                    .foregroundColor(Color.black)
            }
        }
    }
}

struct BatteryIndicator: View {
    @StateObject var vehicleStore : VehicleService

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
                if let batteryLevel = vehicleStore.batteryFillLevel {
                    Text("\(Int(batteryLevel*100))%")
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
    @StateObject var vehicleStore : VehicleService
    var body: some View {
        if vehicleStore.vehicleStatus != nil {
            Button(action: toggleLock) {
                Label(lockStatus(), systemImage: "lock").foregroundColor(lockColor())
            }
            .disabled(lockDisableStatus())
        }
    }
    
    fileprivate func toggleLock() {
        vehicleStore.toggleLock()
    }
    
    fileprivate func lockStatus() -> String {
        switch (vehicleStore.lockState) {
        case .unlocked: return "Unlocked"
        case .locked: return "Locked"
        case .unlocking: return "Unlocking"
        case .locking: return "Locking"
        case .lockError: return "Lock Error"
        case .unknown: return "Unknown"
        }
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
        var status: Color
        switch (vehicleStore.lockState) {
        case .locked:
            status = Color.white
        case .unknown: fallthrough
        case .locking: fallthrough
        case .unlocking: fallthrough
        case .unlocked:
            status = Color.orange
        default:
            status = Color.blue
        }

        return status
    }

}

struct BootStatus: View {
    @StateObject var vehicleStore : VehicleService
    var body: some View {
        if vehicleStore.vehicleStatus != nil {
            Button(action: initiateRemoteStart) {
                Label(bootText(), systemImage: bootImage()).foregroundColor(bootColor())
            }
            .disabled(startDisabledStatus())
        }
    }
    
    fileprivate func initiateRemoteStart() {
        vehicleStore.initiateRemoteStart()
    }
    
    fileprivate func bootText() -> String {
        switch vehicleStore.remoteStartState {
        case .starting: return "Starting"
        case .started: return "Started"
        case .running: return "Running"
        case .off: return "Off"
        default: return "Unknown"
        }
    }
    
    fileprivate func bootImage() -> String {
        switch vehicleStore.remoteStartState {
        case .starting: return "power.dotted"
        case .started: return "power.circle.fill"
        case .running: return "goforward"
        case .off: return "power"
        default: return "xmark.octagon.fill"
        }
    }
    
    fileprivate func startDisabledStatus() -> Bool {
        switch vehicleStore.remoteStartState {
        case .running: return true
        default: return false
        }
    }
    
    fileprivate func bootColor() -> Color {
        switch vehicleStore.remoteStartState {
        case .starting: return Color.yellow
        case .started: return Color.yellow
        case .running: return Color.white
        case .off: return Color.gray
        default: return Color.blue
        }
    }
}


struct VehicleView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleView(vehicleStore: VehicleService(true))
        
    }
}
