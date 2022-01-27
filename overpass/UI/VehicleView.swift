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
        NavigationView {
            ZStack {
                vehicleStore.currentVin.map({
                    Text("VIN: " + $0)
                })
            }
            .navigationTitle("Vehicle")
        }
        .onAppear {
            vehicleStore.startRefresTimer()
        }
        .onDisappear {
            vehicleStore.stopRefreshTimer()
        }
    }
}

struct VehicleView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleView(vehicleStore: VehicleStore())
    }
}
