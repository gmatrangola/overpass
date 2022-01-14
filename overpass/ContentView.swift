//
//  ContentView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authentication: Authentication
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentTab = "account"

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        TabView (selection: $currentTab){

            VehicleView()
                .tabItem {
                    Image(systemName: "car")
                    Text("Vehicle")
                }
                .tag("vehicle")
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
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).previewInterfaceOrientation(.portrait)
        
        }
    }
}
