//
//  AuthView.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State var username = ""
    @State var passwd = ""
    
    var body: some View {
        VStack {
            Text("Ford Pass Login")
                .font(.largeTitle)
            TextField("Email Address", text: $authViewModel.credentials.email)
                .keyboardType(.emailAddress)
            SecureField("Password", text: $authViewModel.credentials.password)
            if authViewModel.showProgressView {
                ProgressView()
            }
            Button("Log in") {
                Task.init {
                    await authViewModel.login(username: authViewModel.credentials.email, password: authViewModel.credentials.password)
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
        AuthView()
    }
}
