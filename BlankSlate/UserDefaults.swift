//
//  UserDefaults.swift
//  BlankSlate
//
//  Created by Ian Terrell on 10/3/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

public let userDefaultsEnvironmentVariable = "USER_DEFAULTS_FIXTURES"

public final class UserDefaults {
    public class func load(fixtures: [Fixture], in environment: inout [String:String]) {
        environment[userDefaultsEnvironmentVariable] = fixtures.toJSON()
    }

    public class func apply() {
        let defaults = Foundation.UserDefaults.standard
        let fixtures: [Fixture] = fixturesFromJSON(in: userDefaultsEnvironmentVariable)
        fixtures.forEach { fixture in
            switch fixture {
            case .clear:
                guard let domain = Bundle.main.bundleIdentifier else {
                    fatalError("No main bundle identifier")
                }
                defaults.removePersistentDomain(forName: domain)
            case let .set(value, type, key):
                switch type {
                case .bool:
                    defaults.set(value as! Bool, forKey: key)
                case .double:
                    defaults.set(value as! Double, forKey: key)
                case .float:
                    defaults.set(value as! Float, forKey: key)
                case .int:
                    defaults.set(value as! Int, forKey: key)
                case .string:
                    defaults.set(value, forKey: key)
                case .url:
                    let url = value as! URL
                    defaults.set(url, forKey: key)
                }
            case let .remove(key):
                defaults.removeObject(forKey: key)
            }
        }
    }
}

extension UserDefaults {
    public enum Fixture {
        case clear
        case set(value: Any, ofType: SettingType, forKey: String)
        case remove(key: String)
    }

    public enum SettingType: String {
        case string
        case bool
        case int
        case float
        case double
        case url
    }
}

extension UserDefaults.Fixture: JSONSerializable {
    func jsonObject() -> [String: String] {
        var output: [String: String] = [:]
        switch self {
        case .clear:
            output["type"] = "clear"
        case let .set(value, valueType, key):
            output["type"] = "set"
            output["value"] = String(describing: value)
            output["value_type"] = valueType.rawValue
            output["key"] = key
        case let .remove(key):
            output["type"] = "remove"
            output["key"] = key
        }
        return output
    }
}

extension UserDefaults.Fixture: JSONInitializable {
    init(json: [String : String]) throws {
        guard let type = json["type"] else {
            throw FixtureError.typeIsRequired
        }
        switch type {
        case "clear":
            self = .clear
        case "set":
            guard let key = json["key"] else {
                throw FixtureError.keyIsRequiredForType(type)
            }
            guard let value = json["value"] else {
                throw FixtureError.valueIsRequiredForSet
            }
            guard let valueType = json["value_type"] else {
                throw FixtureError.valueTypeIsRequiredForSet
            }
            guard let settingType = UserDefaults.SettingType(rawValue: valueType) else {
                throw FixtureError.invalidValueType(valueType)
            }
            var newValue: Any?
            switch settingType {
            case .string:
                newValue = value
            case .bool:
                newValue = Bool(value)
            case .int:
                newValue = Int(value)
            case .float:
                newValue = Float(value)
            case .double:
                newValue = Double(value)
            case .url:
                newValue = URL(string: value)
            }
            guard let typedValue = newValue else {
                throw FixtureError.invalidValueForValueType(value, valueType)
            }
            self = .set(value: typedValue, ofType: settingType, forKey: key)
        case "remove":
            guard let key = json["key"] else {
                throw FixtureError.keyIsRequiredForType(type)
            }
            self = .remove(key: key)
        default:
            throw FixtureError.invalidType(type)
        }
    }

    public enum FixtureError: Error {
        case typeIsRequired
        case invalidType(String)
        case keyIsRequiredForType(String)
        case valueIsRequiredForSet
        case valueTypeIsRequiredForSet
        case invalidValueType(String)
        case invalidValueForValueType(String, String)
    }
}
