//
//  ContentView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject var vehicleService = VehicleService()

    fileprivate func handleMainAppears() {
        if vehicleService.vins.isEmpty {
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer().frame(width: 5)
                    NavigationLink(destination: AuthView(vehicleStore: vehicleService)) {
                        Image(systemName: "gearshape")
                    }
                    if let name = vehicleService.nickName {
                        Text(name)
                        Spacer()
                    }
                    if vehicleService.networkActivity {
                        ProgressView()
                            .padding()
                    }
                }
                HStack(alignment: .top, spacing: 0) {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if vehicleService.plugState == .pluggedIn {
                            Spacer().frame(height:155)
                            ChargeStatusView(vehicleService: vehicleService)
                        }
                    }
                    VehicleView(vehicleService: vehicleService).frame(alignment: .leading)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            vehicleService.startRefreshTask()
        }
        .onDisappear {
            vehicleService.stopRefreshTask()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vehicleService: VehicleService(true)).previewInterfaceOrientation(.portrait)
        
    }
}
