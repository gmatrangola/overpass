//
//  APIService.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation
import KeychainSwift

enum AccessError: Error {
    case noToken
    case invalidToken
}

class APIService {
    static let shared = APIService()
    static let zoneId = ["UK_Europe": "1E8C7794-FF5F-49BC-9596-A1E0C86C5B19",
                         "Australia": "5C80A6BB-CF0D-4A30-BDBF-FC804B5C1A98",
                         "NA": "71A3AD0A-CF46-4CCF-B473-FC7FE5BC4592"]
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
    
    func login(credentials: Credentials) async throws {
        let grantToken = try await requestAuth(credentials: credentials)
        let authToken = try await requestToken(grant: grantToken)
        print ("authToken = \(authToken)")
        let _ = try await getVehicleStatus()
    }
    
    func requestAuth(credentials: Credentials) async throws -> GrantToken {
        let url = URL(string: "https://sso.ci.ford.com/oidc/endpoint/default/token")!
        var request = URLRequest(url: url)

        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
             forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8",
             forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let body : Data = "client_id=9fb503e0-715b-47e8-adfd-ad4b7770f73b&grant_type=password&username=\(credentials.email)&password=\(credentials.password)".data(using: .utf8)!
        request.httpBody = body
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        // vs let session = URLSession.shared
          // make the request
        let (data, _) = try await session.data(for:request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let container = try decoder.decode(GrantToken.self, from: data)
        return container
    }
    
    func requestToken(grant: GrantToken) async throws -> AuthToken {
        print ("Token Request")
        return try await requestToken(authString: grant.accessToken)
    }

    func refreshToken(auth: AuthToken) async throws -> String {
        print("Token Refreshed")
        let result = try await requestToken(authString: auth.refreshToken)
        print("Token Refreshed \(result)")
        return result.accessToken
    }

    func requestToken(authString: String) async throws -> AuthToken {
        let url = URL(string: "https://api.mps.ford.com/api/oauth2/v1/token")!
        var request = URLRequest(url: url)

        request.setValue("application/json",
             forHTTPHeaderField: "content-type")
        request.setValue(APIService.zoneId["NA"]!, forHTTPHeaderField: "application-id")
        request.httpMethod = "PUT"
        request.httpBody = "{ \"code\": \"\(authString)\"}".data(using: .utf8)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        // vs let session = URLSession.shared
          // make the request
        let (data, _) = try await session.data(for:request)
        let date = Date()
        var authToken = try jsonDecoder().decode(AuthToken.self, from: data)
        authToken.expiresAt = Calendar.current.date(byAdding: DateComponents(second: authToken.expiresIn), to: date)!
        authToken.refreshExpiresAt = Calendar.current.date(byAdding: DateComponents(second: authToken.refreshExpiresIn), to: date)!
        keychain.set(try jsonEncoder().encode(authToken), forKey: "token")
        print("requestToken Succeeded")
        return authToken

    }

    func validToken() async throws -> String {
        let data = keychain.getData("token")
        if let tokenData = data {
            let authToken = try jsonDecoder().decode(AuthToken.self, from: tokenData)
            print ("validTokeN: authToken = \(authToken)")

            if (authToken.expiresAt! > Date()) {
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
    
    func getVehicleStatus() async throws {
        let vin = "VIN_HARDCODE_FOR_TESTING"
        let data = try await makeFordRequest(url: URL(string: "https://usapi.cv.ford.com/api/vehicles/v4/\(vin)/status")!)
        print ("VehicleStatus = \(String(data: data, encoding:.utf8)!)")
    }
    
    func makeFordRequest(url: URL, body: Data? = nil) async throws -> Data {
        let authToken = try await validToken()
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(APIService.zoneId["NA"]!, forHTTPHeaderField: "application-id")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("FordPass/5 CFNetwork/1327.0.4 Darwin/21.2.0", forHTTPHeaderField: "User-Agent")
        request.setValue(authToken, forHTTPHeaderField: "auth-token")

        if (body != nil) {
            request.httpBody = try jsonEncoder().encode(body)
        }

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let (data, _) = try await session.data(for:request)
        return data
   }
    
}
