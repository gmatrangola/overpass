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
    @Published var vin = ""
    
    var loginDisabled: Bool {
        credentials.email.isEmpty || credentials.password.isEmpty || !validVin()
    }
    
    private func validVin() -> Bool {
        let alhpanumRegex = #"[A-Z0-9]*"#
        return !vin.isEmpty && vin.count == 17 && vin.range(of: alhpanumRegex, options: .regularExpression) != nil
    }
    
    func login(username: String, password: String) async -> Bool {
        var success = false
        DispatchQueue.main.async { self.showProgressView = true }
        do {
            try await AuthApi.shared.login(username: username, password: password)
            success = true
        }
        catch {
            print("--- Unexpected error \(error)")
            self.errorStatus = Authentication.AuthenticationError.invalidCredentials
        }
        DispatchQueue.main.async { self.showProgressView = false }
        return success
    }
}
