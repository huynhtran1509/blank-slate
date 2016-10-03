//
//  Keychain.swift
//  BlankSlate
//
//  Created by Ian Terrell on 10/3/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation
import SAMKeychain

public let keychainEnvironmentVariable = "KEYCHAIN_FIXTURES"

public final class Keychain {
    public class func load(fixtures: [Fixture], in environment: inout [String:String]) {
        environment[keychainEnvironmentVariable] = fixtures.toJSON()
    }

    public class func apply() {
        let fixtures: [Fixture] = fixturesFromJSON(in: keychainEnvironmentVariable)
        fixtures.forEach { fixture in
            switch fixture {
            case let .set(password, service, account):
                SAMKeychain.setPassword(password, forService: service, account: account)
            case let .delete(service, account):
                SAMKeychain.deletePassword(forService: service, account: account)
            }
        }
    }
}

extension Keychain {
    public enum Fixture {
        case set(password: String, service: String, account: String)
        case delete(service: String, account: String)
    }
}

extension Keychain.Fixture: JSONSerializable {
    func jsonObject() -> [String: String] {
        var output: [String: String] = [:]
        switch self {
        case let .set(password, service, account):
            output["type"] = "set"
            output["password"] = password
            output["service"] = service
            output["account"] = account
        case let .delete(service, account):
            output["type"] = "delete"
            output["service"] = service
            output["account"] = account
        }
        return output
    }
}

extension Keychain.Fixture: JSONInitializable {
    init(json: [String : String]) throws {
        guard let type = json["type"] else {
            throw FixtureError.typeIsRequired
        }
        switch type {
        case "set":
            guard let password = json["password"] else {
                throw FixtureError.passwordIsRequiredForSet
            }
            guard let service = json["service"] else {
                throw FixtureError.serviceIsRequired
            }
            guard let account = json["account"] else {
                throw FixtureError.accountIsRequired
            }
            self = .set(password: password, service: service, account: account)
        case "delete":
            guard let service = json["service"] else {
                throw FixtureError.serviceIsRequired
            }
            guard let account = json["account"] else {
                throw FixtureError.accountIsRequired
            }
            self = .delete(service: service, account: account)
        default:
            throw FixtureError.invalidType(type)
        }
    }

    public enum FixtureError: Error {
        case typeIsRequired
        case invalidType(String)
        case passwordIsRequiredForSet
        case serviceIsRequired
        case accountIsRequired
    }
}
