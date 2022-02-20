//
//  VehicleView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI

struct VehicleView: View {
    @StateObject var vehicleService : VehicleService
    var body: some View {
        ZStack(alignment: .top) {
            Image("Ford_Mustang_Mach-E_4_2020_TOP_W_PORTRATE")
                .resizable()
                .scaledToFit()
                .frame(alignment: .topLeading)
            VStack(alignment: .subCentre) {
                Spacer().frame(height: 30)
                HStack {
                    if vehicleService.plugState == .pluggedIn {
                        VStack {
                            Spacer().frame(height:70)
                            Image(systemName: "powerplug")
                                .foregroundColor(Color.textColor)
                        }
                        Spacer().frame(width:20)
                    }
                    BatteryIndicator(vehicleService: vehicleService)
                        .frame(width: 200, height: 200)
                        .alignmentGuide(.subCentre) { d in d.width / 2}
                }
                GeometryReader { geometry in EmptyView() }
            }
            .alignmentGuide(.subCentre) { d in d.width/2}
            VStack {
                Spacer().frame(height:30)
                ChargeStatus(vehicleService: vehicleService)
                Spacer().frame(height: 50)
                BootStatus(vehicleStore: vehicleService)
                Spacer().frame(height: 12.0)
                LockStatus(vehicleStore: vehicleService)
            }
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


struct BatteryIndicator: View {
    @StateObject var vehicleService : VehicleService

    var body: some View {
        ZStack(alignment: .top) {
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 12.0, dash: [8]))
                
                .rotationEffect(Angle(degrees: -180))
            if let target = vehicleService.chargeTarget {
                Circle()
                    .trim(from: 0.0, to: target/2)
                    .stroke(Color.black, lineWidth: 15.0)
                    .rotationEffect(Angle(degrees: -180))
                Circle()
                    .trim(from: 0.0, to: target/2 - 0.004)
                    .stroke(Color.gray, lineWidth: 12.0)
                    .rotationEffect(Angle(degrees: -180))
            }
            if let fill = vehicleService.batteryFillLevel {
                Circle()
                    .trim(from: 0.0, to: fill/2)
                    .stroke(fillColor(), lineWidth: 12.0)
                    .rotationEffect(Angle(degrees: -180))
            }
        }
    }
    
    fileprivate func fillColor() -> Color {
        if let bat = vehicleService.batteryFillLevel {
            if bat < 0.10 {
                return Color.errorColor
            }
            else if bat < 0.30 {
                return Color.warningColor
            }
            else if bat < 0.50 {
                return Color.nominalColor
            }
            else {
                return .goodColor
            }
        }
        return Color.gray
    }
}

struct ChargeStatus: View {
    @StateObject var vehicleService: VehicleService
    var body: some View {
        VStack() {
            Spacer().frame(height:20)
            if let batteryLevel = vehicleService.batteryFillLevel {
                Text("\(Int(batteryLevel*100))%")
                    .font(.custom("HelveticaNeue", size: 20.0))
                    .foregroundColor(.black)
            }
            if let gom = vehicleService.kmToEmpty {
                let miles = Measurement(value: gom, unit: UnitLength.kilometers).converted(to: UnitLength.miles)
                Text("\(Int(miles.value)) \(miles.unit.symbol)")
                    .foregroundColor(.black)
            }
            Spacer().frame(height:10)
            if let started = vehicleService.vehicleStatus?.chargeStartTime?.value {
                let begin = dateFormat(started)
                if let end = vehicleService.vehicleStatus?.chargeEndTime?.value {
                    let finish = dateFormat(end)
                    Text(begin + "-" + finish)
                        .allowsTightening(true)
                        .frame(width:200)
                        .lineLimit(3)
                        .foregroundColor(Color.black)
                }

            }
            if vehicleService.chargeState == .chargeScheduled || (vehicleService.chargeState == .chargeTargetReached && vehicleService.batteryFillLevel! < 0.999) {
                Spacer().frame(height:80)
                Button {
                    
                } label: {
                    Label("Charge to 100%", systemImage: "bolt.circle")
                }
                
            }
            if vehicleService.chargeState == .acCharge || vehicleService.chargeState == .level3Charging {
                Spacer().frame(maxHeight:20)
                Button {
                } label: {Label("Stop", systemImage: "bolt.slash").font(.caption)
                }
            }
            if  vehicleService.chargeState == .forceCharge {
                Spacer().frame(maxHeight:20)
                Button {
                    
                } label: {Label ("Resume", systemImage: "bolt.badge.a").font(.caption)}
            }
        }

    }
    
    func dateFormat(_ text: String) -> String {
        
        let toDate = DateFormatter()
        toDate.dateFormat = "MM-dd-yyyy HH:mm:ss"
        if let date = toDate.date(from: text) {
            let dateOut = DateFormatter()
            dateOut.timeStyle = .short
            if Calendar.current.isDateInToday(date) {
                dateOut.dateStyle = .none
            }
            else {
                dateOut.dateStyle = .short
            }
            dateOut.doesRelativeDateFormatting = true
            return dateOut.string(from: date)
                .replacingOccurrences(of: " PM", with: "pm")
                .replacingOccurrences(of: " AM", with: "am")
        }
        else {
            return ""
        }
    }
}

struct LockStatus: View {
    @StateObject var vehicleStore : VehicleService
    var body: some View {
        if vehicleStore.vehicleStatus != nil {
            Button(action: toggleLock) {
                Label(lockStatus(), systemImage: lockImage()).foregroundColor(lockColor())
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
    
    fileprivate func lockImage() -> String {
        switch (vehicleStore.lockState) {
        case .unlocked: return "lock.open"
        case .locked: return "lock"
        case .unlocking: return "lock.rotation.open"
        case .locking: return "lock.rotation.open"
        case .lockError: return "lock.slash"
        case .unknown: return "lock.slash"
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
        Group {
            VehicleView(vehicleService: VehicleService(true))
                .preferredColorScheme(.dark)
            VehicleView(vehicleService: VehicleService(true))
                .preferredColorScheme(.light)
        }
        
    }
}
