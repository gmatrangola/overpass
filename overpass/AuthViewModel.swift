//
//  AuthViewModel.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation

class AuthViewModel : ObservableObject {
    @Published var credentials = Credentials()
    @Published var showProgressView = false
    @Published var error: Authentication.AuthenticationError?
    
    var loginDisabled: Bool {
        credentials.email.isEmpty || credentials.password.isEmpty
    }
    
    func login() async -> Bool {
        var result : Bool
        DispatchQueue.main.async { self.showProgressView = true }
        do {
            try await APIService.shared.login(credentials: credentials)
            result = Bool(true)
        }
        catch {
            print("Unexpected error \(error)")
            self.error = Authentication.AuthenticationError.invalidCredentials
            credentials = Credentials()
            result = Bool(false)
        }
        DispatchQueue.main.async { self.showProgressView = false }
        return result
    }
}
