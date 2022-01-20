//
//  APIService.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation
import KeychainSwift
import SwiftUI

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
        request.setValue(APIService.zoneId["NA"]!, forHTTPHeaderField: "application-id")
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
    
    func getVehicleStatus(vin: String) async throws -> VehicleStatusMessage {
        let data = try await makeFordRequest(url: URL(string: "https://usapi.cv.ford.com/api/vehicles/v4/\(vin)/status?lrdt=01-01-1970%2000:00:00")!)
        print ("VehicleStatus = \(String(data: data, encoding:.utf8)!)")
        return try getApiDecoder().decode(VehicleStatusMessage.self, from: data)
    }
    
    func getVehicleInfo(vin: String) async throws -> VehicleInfo {
        let data = try await makeFordRequest(url: URL(string: "https://usapi.cv.ford.com/api/users/vehicles/\(vin)/detail?lrdt=01-01-1970%2000:00:00")!)
        print ("VehicleInfo = \(String(data: data, encoding:.utf8)!)")
        return try getApiDecoder().decode(VehicleInfo.self, from: data)
    }
    
    func getApiDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    func makeFordRequest(url: URL, body: Data? = nil, retries: Int = 4) async throws -> Data {
        let authToken = try await validToken()
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIService.zoneId["NA"]!, forHTTPHeaderField: "application-id")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("FordPass/2 CFNetwork/1312 Darwin/21.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue(authToken, forHTTPHeaderField: "auth-token")
        request.httpMethod = "GET"
    
        if (body != nil) {
            request.httpBody = try jsonEncoder().encode(body)
        }

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        print("makeFordRequest session = \(session.debugDescription) request = \(request.allHTTPHeaderFields) authToken = \(authToken)")
        let (data, response) = try await session.data(for:request)
        if let httpResponse = response as? HTTPURLResponse {
            if (httpResponse.statusCode == 200) {
                return data
            }
            else if (httpResponse.statusCode == 401 && retries > 0) {
                print ("httpResponse.statusCode: \(httpResponse.statusCode)")
                let _ = try await validToken(forceRefresh: true)
                return try await makeFordRequest(url: url, body: body, retries: retries-1)
            }
            else {
                if (retries > 0) {
                    return try await makeFordRequest(url: url, body: body, retries: retries-1)
                }
                else {
                    throw RestError.httpError(status: httpResponse.statusCode, body: body)
                }
            }
        }
        else {
            return data
        }
   }
    
}
