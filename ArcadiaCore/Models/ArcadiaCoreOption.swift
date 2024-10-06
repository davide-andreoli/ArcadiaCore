//
//  ArcadiaCoreOptions.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 17/05/24.
//

import Foundation

extension retro_variable: Equatable, Hashable {
    public static func == (lhs: retro_variable, rhs: retro_variable) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}

public struct ArcadiaCoreOption: Hashable {
    
    
    public let key: String
    public let description: String?
    public let values: [String]?
    public let selectedValue: String?
    public let retroVariable: retro_variable?
    
    init(key: String, description: String, values: [String]) {
        self.key = key
        self.description = description
        self.values = values
        self.selectedValue = nil
        self.retroVariable = nil
    }
    
    public init(key: String, selectedValue: String) {
        self.key = key
        self.selectedValue = selectedValue
        self.values = nil
        self.description = nil
        self.retroVariable = retro_variable(key: strdup(key), value: strdup(selectedValue))
    }
    
    public func getRetroVariable() -> retro_variable {
        return self.retroVariable!
    }
}
