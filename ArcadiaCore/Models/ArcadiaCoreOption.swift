//
//  ArcadiaCoreOptions.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 17/05/24.
//

import Foundation

public struct ArcadiaCoreOption: Hashable {
    public let key: String
    public let description: String?
    public let values: [String]?
    public let selectedValue: String?
    
    init(key: String, description: String, values: [String]) {
        self.key = key
        self.description = description
        self.values = values
        self.selectedValue = nil
    }
    
    public init(key: String, selectedValue: String) {
        self.key = key
        self.selectedValue = selectedValue
        self.values = nil
        self.description = nil
    }
    
    public func getRetroVariable() -> retro_variable {
        let customKey = self.key
        let customValue = self.selectedValue
        let keyCString = strdup(customKey)
        let valueCString = strdup(customValue)
        let customVariable = retro_variable(key: keyCString, value: valueCString)
        free(keyCString)
        free(valueCString)
        return customVariable
    }
}
