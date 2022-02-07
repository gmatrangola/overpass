//
//  ContentView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var currentTab = "vehicle"
    @StateObject private var vehicleStore = VehicleService()

    fileprivate func handleMainAppears() {
        if vehicleStore.vins.isEmpty {
            currentTab = "account"
        }
    }
    
    var body: some View {
        TabView (selection: $currentTab){

            VehicleView(vehicleStore: vehicleStore)
                .tabItem {
                    Image(systemName: "car")
                    Text("Vehicle")
                }
                .tag("vehicle")
                .onAppear {
                    handleMainAppears()
                }
            AuthView(vehicleStore: vehicleStore)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Account")
                }
                .tag("account")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().previewInterfaceOrientation(.portrait)
        
        }
    }
}
