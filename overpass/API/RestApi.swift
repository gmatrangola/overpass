//
//  RestApi.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/20/22.
//

import Foundation
import KeychainSwift

class RestApi {
    private let keychain = KeychainSwift()
    private let auth = AuthApi.shared

    func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    func makeFordRequest(string: String, method: String = "GET", body: String? = nil, retries: Int = 4) async throws -> Data{
        return try await makeFordRequest(url: URL(string: string)!, method: method, body: body, retries: retries)
    }
    
    func makeFordRequest(url: URL, method: String = "GET", body: String? = nil, retries: Int = 4) async throws -> Data {
        let authToken = try await auth.validToken()
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Zones.zoneId["NA"]!, forHTTPHeaderField: "application-id")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("FordPass/2 CFNetwork/1312 Darwin/21.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue(authToken, forHTTPHeaderField: "auth-token")
        request.httpMethod = method
    
        if (body != nil) {
            request.httpBody = body!.data(using: .utf8)
        }

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for:request)
        if let httpResponse = response as? HTTPURLResponse {
            if (httpResponse.statusCode == 200) {
                return data
            }
            else if (httpResponse.statusCode == 401 && retries > 0) {
                print ("makeFordRequest: Forcing Auth Refresh")
                let _ = try await auth.validToken(forceRefresh: true)
                return try await makeFordRequest(url: url, body: body, retries: retries-1)
            }
            else {
                print ("makeFordRequest: \(url) \n   bad HTTP Response \(httpResponse.statusCode) \n   body: \(String(decoding: data, as: UTF8.self)) \n   retries: \(retries)")
                if (retries > 0) {
                    return try await makeFordRequest(url: url, body: body, retries: retries-1)
                }
                else {
                    throw RestError.httpError(status: httpResponse.statusCode)
                }
            }
        }
        else {
            return data
        }
   }

}
