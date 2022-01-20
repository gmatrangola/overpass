//
//  Credentials.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/3/22.
//

import Foundation

struct TokenError: Codable {
    var errorDescription = ""
    var error: String = ""
}

enum AccessError: Error {
    case noToken
    case invalidToken
    case httpError(status: Int, tokenError: TokenError?)
}

struct Credentials: Codable {
    var email: String = ""
    var password: String = ""
}

struct GrantToken: Codable {
    var refreshToken: String
    var expiresIn: Int
    var accessToken: String
    var tokenType: String
    var grantId: String
}

struct AuthToken: Codable {
    var accessToken: String
    var cat1Token: String
    var refreshToken: String
    var error: String?
    var expiresIn: Int
    var expiresAt: Date?
    var refreshExpiresIn: Int
    var refreshExpiresAt: Date?
}
