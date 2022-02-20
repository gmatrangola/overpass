//
//  PlugStatusView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 2/19/22.
//

import SwiftUI

struct ChargeStatusView: View {
    @StateObject var vehicleService : VehicleService

    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                switch vehicleService.chargeState {
                case .chargeScheduled:
                    Image(systemName: "bolt.badge.a").foregroundColor(Color.textColor)
                case .notReady:
                    Image(systemName: "bolt.heart").foregroundColor(Color.textColor)
                case .chargeTargetReached:
                    Image(systemName: "bolt.heart").foregroundColor(Color.textColor)
                case .forceCharge:
                    Image(systemName: "bolt.circle").foregroundColor(Color.warningColor)
                case .acCharge:
                    Image(systemName: "bolt").foregroundColor(Color.chargingColor)
                case .level3Charging:
                    Image(systemName: "bolt.fill").foregroundColor(Color.chargingColor)
                default:
                    Image(systemName: "bolt").foregroundColor(Color.chargingColor)
                }
            }
        }
    }
}

struct ChargeStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ChargeStatusView(vehicleService: VehicleService(true)).background(.yellow)
    }
}
