//
//  AuthView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI

struct AuthView: View {
    @StateObject var vehicleStore: VehicleService
    @StateObject private var authViewModel = AuthViewModel()
    var body: some View {
        VStack {
            Text("Ford Pass Login")
                .font(.largeTitle)
            TextField("Email Address", text: $authViewModel.credentials.email)
                .keyboardType(.emailAddress)
            SecureField("Password", text: $authViewModel.credentials.password)
            TextField("VIN", text: $authViewModel.vin)
                .disableAutocorrection(true)
                .autocapitalization(.allCharacters)
            if (authViewModel.showProgressView) {
                ProgressView()
            }
            Button("Log in") {
                Task.init {
                    let success = await authViewModel.login(username: authViewModel.credentials.email, password: authViewModel.credentials.password)
                    if success {
                        vehicleStore.addVin(vin: authViewModel.vin)
                        vehicleStore.currentVin = authViewModel.vin
                    }
                }
            }
            .disabled(authViewModel.loginDisabled)
            .padding(.bottom,20)
            Spacer()
        }
        .autocapitalization(.none)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
        .disabled(authViewModel.showProgressView)
        .alert(item: $authViewModel.errorStatus) { error in
            Alert(title: Text("Invlid Login"), message: Text(error.localizedDescription))
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(vehicleStore: VehicleService())
    }
}
