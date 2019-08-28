//
//  UserDefault.swift
//  JanitorKit
//
//  Created by Ben Leggiero on 7/19/19.
//  Copyright © 2019 Ben Leggiero. All rights reserved.
//

import Foundation
import SwiftUI



@propertyWrapper
public struct UserDefault<Value>: DynamicProperty where Value: Codable {
    let defaultValue: Value
    let key: String
    let userDefaults: UserDefaults
    private var observerShim: ObserverShim! = nil

    init(wrappedValue: Value, _ key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = wrappedValue
        self.userDefaults = userDefaults
        
        if !isSerialized() {
            setValue(wrappedValue)
        }
        
        self.observerShim = ObserverShim(self)
    }

    public var wrappedValue: Value {
        get {
            return value()
        }
        nonmutating set {
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
    
    
    private class ObserverShim: NSObject {
        let parent: Pointer<UserDefault>
        
        init(_ parent: UserDefault) {
            self.parent = *parent
            
            super.init()
            
            parent.userDefaults.addObserver(self, forKeyPath: parent.key, options: .new, context: nil)
        }
        
        
        deinit {
            parent.pointee.userDefaults.removeObserver(self, forKeyPath: parent.pointee.key)
        }
        
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            parent.pointee.update()
        }
    }
}
