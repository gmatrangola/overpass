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
                    NavigationLink(destination: AuthView(vehicleStore: vehicleService)) {
                        Image(systemName: "gearshape")
                            .padding()
                    }
                    Spacer()
                    if let name = vehicleService.nickName {
                        Text(name)
                        Spacer()
                    }
                    if vehicleService.networkActivity {
                        ProgressView()
                            .padding()
                    }
                }
                Spacer()
                VehicleView(vehicleStore: vehicleService)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vehicleService: VehicleService(true)).previewInterfaceOrientation(.portrait)
        
    }
}
