//
//  AuthApi.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/20/22.
//

import Foundation
import KeychainSwift

class AuthApi {
    static let shared = AuthApi()
    
    let keychain = KeychainSwift()
    
    func jsonDecoder() throws -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    func jsonEncoder() throws -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
    func login(username: String, password: String) async throws {
        let grantToken = try await requestAuth(username: username, password: password)
        let _ = try await requestToken(grant: grantToken)
    }
    
    func requestAuth(username: String, password: String) async throws -> GrantToken {
        let url = URL(string: "https://sso.ci.ford.com/oidc/endpoint/default/token")!
        var request = URLRequest(url: url)

        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*",forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("FordPass/2 CFNetwork/1312 Darwin/21.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Basic ZWFpLWNsaWVudDo=", forHTTPHeaderField: "authorization")
        request.httpMethod = "POST"
        let body : Data = "client_id=9fb503e0-715b-47e8-adfd-ad4b7770f73b&grant_type=password&username=\(username)&password=\(password)".data(using: .utf8)!
        request.httpBody = body
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        // vs let session = URLSession.shared
          // make the request
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let (data, response) = try await session.data(for:request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print ("requestAuth \(username) httpResponse.statusCode: \(httpResponse.statusCode) \(String(data: data, encoding: String.Encoding.utf8)!)")
            throw AccessError.httpError(status: httpResponse.statusCode, tokenError: try decoder.decode(TokenError.self, from: data))
        }
        print("requestAuth \(username), data= \(String(decoding: data, as: UTF8.self))")
        let container = try decoder.decode(GrantToken.self, from: data)
        return container
    }
    
    func requestToken(grant: GrantToken) async throws -> AuthToken {
        return try await requestToken(url: URL(string: "https://api.mps.ford.com/api/oauth2/v1/token")!, tokenField: "code", authString: grant.accessToken)
    }

    func refreshToken(auth: AuthToken) async throws -> String {
        let result = try await requestToken(url: URL(string: "https://api.mps.ford.com/api/oauth2/v1/refresh")!, tokenField: "refresh_token", authString: auth.refreshToken)
        print("Token Refreshed \(result)")
        return result.accessToken
    }
    
    func requestToken(url: URL, tokenField: String, authString: String) async throws -> AuthToken {
        print("requestToken: \(tokenField), \(authString)")
        var request = URLRequest(url: url)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*",forHTTPHeaderField: "Accept")
        request.setValue(Zones.zoneId["NA"]!, forHTTPHeaderField: "application-id")
        request.setValue("en-US,en;q0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("FordPass/5 CFNetwork/1327.0.4 Darwin/21.2.0", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Basic ZWFpLWNsaWVudDo=", forHTTPHeaderField: "authorization")

        request.httpMethod = "PUT"
        request.httpBody = "{ \"\(tokenField)\": \"\(authString)\"}".data(using: .utf8)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        // vs let session = URLSession.shared
          // make the request
        let (data, response) = try await session.data(for:request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print ("requestToken \(authString) httpResponse.statusCode: \(httpResponse.statusCode) body: \(String(data: data, encoding:.utf8)!)")
            throw AccessError.httpError(status: httpResponse.statusCode, tokenError: try jsonDecoder().decode(TokenError.self, from: data))
        }
        let date = Date()
        print("requestToken Success: body: \(String(data: data, encoding:.utf8)!)")
        var authToken = try jsonDecoder().decode(AuthToken.self, from: data)
        authToken.expiresAt = Calendar.current.date(byAdding: DateComponents(second: authToken.expiresIn), to: date)!
        authToken.refreshExpiresAt = Calendar.current.date(byAdding: DateComponents(second: authToken.refreshExpiresIn), to: date)!
        keychain.set(try jsonEncoder().encode(authToken), forKey: "token")
        return authToken
    }

    func validToken(forceRefresh: Bool = false) async throws -> String {
        let data = keychain.getData("token")
        if let tokenData = data {
            let authToken = try jsonDecoder().decode(AuthToken.self, from: tokenData)
            print ("Refresh Token expires \(authToken.expiresAt!.description)")
            if (forceRefresh || authToken.expiresAt! < Date()) {
                print("Refreshing Toekn \(forceRefresh) \(authToken.expiresAt!)")
                return try await refreshToken(auth: authToken)
            }
            else {
                print("Using saved token")
                return authToken.accessToken
            }
        }
        else {
            throw AccessError.noToken
        }
    }

}
