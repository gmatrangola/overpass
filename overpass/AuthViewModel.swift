//
//  AuthViewModel.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation

@MainActor
class AuthViewModel : ObservableObject {
    @Published var credentials = Credentials()
    @Published var showProgressView = false
    @Published var errorStatus: Authentication.AuthenticationError?
    
    var loginDisabled: Bool {
        credentials.email.isEmpty || credentials.password.isEmpty
    }
    
    func login(username: String, password: String) async {
        DispatchQueue.main.async { self.showProgressView = true }
        do {
            try await APIService.shared.login(username: username, password: password)
        }
        catch {
            print("--- Unexpected error \(error)")
            self.errorStatus = Authentication.AuthenticationError.invalidCredentials
        }
        DispatchQueue.main.async { self.showProgressView = false }
    }
}
