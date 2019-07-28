//
//  UserDefault.swift
//  JanitorKit
//
//  Created by Ben Leggiero on 7/19/19.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation



@propertyWrapper
public struct UserDefault<Value> where Value: Codable {
    let defaultValue: Value
    let key: String
    let userDefaults: UserDefaults

    init(initialValue: Value, _ key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = initialValue
        self.userDefaults = userDefaults
        
        if !isSerialized() {
            setValue(initialValue)
        }
    }

    public var wrappedValue: Value {
        get {
            return value()
        }
        set {
            setValue(newValue)
        }
    }
    
    
    private func setValue(_ newValue: Value) {
        guard let newString = try? newValue.jsonString() else {
            print("Could not create JSON string out of the new value; preserving existing defaults")
            assertionFailure()
            return
        }
        userDefaults.set(newString, forKey: key)
        userDefaults.synchronize()
    }
    
    
    private func value() -> Value {
        if let existingValueString = userDefaults.string(forKey: key) {
            guard let existingValue = try? Value(jsonString: existingValueString) else {
                print("Could not parse JSON string out of the existing value; returning nil")
                assertionFailure()
                return defaultValue
            }
            return existingValue
        }
        else {
            return defaultValue
        }
    }
    
    
    private func isSerialized() -> Bool {
        userDefaults.synchronize()
        return nil != userDefaults.string(forKey: key)
    }
}
