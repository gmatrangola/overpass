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
    let vin = "VIN"

    var body: some View {
        TabView (selection: $currentTab){

            VehicleView()
                .tabItem {
                    Image(systemName: "car")
                    Text("Vehicle")
                }
                .tag("vehicle")
                .onAppear {
                    Task {
                        do {
                            let status = try await APIService.shared.getVehicleStatus(vin: vin)
                            print("got status = \(status)")
                            let info = try await APIService.shared.getVehicleInfo(vin: vin)
                            print( "got info = \(info)")
                        }
                        catch AccessError.noToken {
                            print("Error no token switching to login tab")
                            DispatchQueue.main.async { currentTab = "account" }
                        } catch let DecodingError.dataCorrupted(context) {
                            print(context)
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("Key '\(key)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.valueNotFound(value, context) {
                            print("Value '\(value)' not found:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        } catch let DecodingError.typeMismatch(type, context)  {
                            print("Type '\(type)' mismatch:", context.debugDescription)
                            print("codingPath:", context.codingPath)
                        }
                        catch {
                            print("Unexpected Error \(error)")
                        }
                    }
                }
            AuthView()
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
