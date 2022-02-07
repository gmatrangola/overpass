//
//  CurrentState.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/29/22.
//

import Foundation

enum CurrentState {
    case ready
    case noAccount
    case locking
    case unlocking
    case authError(_ message: String)
    case restError(_ message: String)
    case savedStatus(_ date: Date)
    case updated(_ date: Date)
    case unkownError(_ description: String)
}

enum LockState {
    case unknown
    case locked
    case unlocked
    case locking
    case unlocking
    case lockError(_ message: String)
}

enum RemoteStartState {
    case unknown
    case off
    case running
    case started(_ timeMinutes: Int?)
    case starting
    case startFailed
    case startError(_ message: String)
}

enum PlugState {
    case unknown
    case pluggedIn
    case unplugged
}

enum ChargeState {
    case unknown
    case chargeScheduled
    case chargeTargetReached
    case forceCharge
    case acCharge
    case level3Charging
}

enum StateError: Error {
    case unknownLockState(_ description: String)
    case lockError(_ message: String)
}
