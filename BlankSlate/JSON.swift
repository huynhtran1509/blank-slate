//
//  Extensions.swift
//  BlankSlate
//
//  Created by Ian Terrell on 10/3/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

protocol JSONSerializable {
    func jsonObject() -> [String: String]
}

protocol JSONInitializable {
    init(json: [String: String]) throws
}

extension Collection where Iterator.Element: JSONSerializable {
    func toJSON() -> String {
        let mapped = self.map { $0.jsonObject() }
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: mapped, options: []),
            let json = String(data: jsonObject, encoding: .utf8)
            else {
                fatalError("Could not create JSON")
        }
        return json
    }
}

func fixturesFromJSON<T: JSONInitializable>(in environmentVariable: String) -> [T] {
    guard let jsonString = ProcessInfo().environment[environmentVariable] else {
        return []
    }
    guard let jsonData = jsonString.data(using: .utf8) else {
        fatalError("Could not make data from JSON string")
    }
    let jsonObject: [[String:String]]
    do {
        guard let object = try JSONSerialization.jsonObject(with: jsonData,
                                                            options: .allowFragments) as? [[String:String]] else {
                                                                fatalError("JSON of wrong type")
        }
        jsonObject = object
    } catch {
        fatalError("Could not properly parse JSON: \(error)")
    }
    do {
        return try jsonObject.map({ try T(json: $0) })
    } catch {
        fatalError("Could not reconstitute fixtures: \(error)")
    }
}
