//
//  UserApi.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/20/22.
//

import Foundation

class UserApi : RestApi {
    static let shared = UserApi()
    
    func getUserData() async throws {
        let data = try await makeFordRequest(string: "https://api.mps.ford.com/api/users")
        print ("user: \(String(data: data, encoding:.utf8)!)")
    }
}
