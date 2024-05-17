//
//  ArcadiaCoreOptions.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 17/05/24.
//

import Foundation

public struct ArcadiaCoreOption {
    let key: String
    let description: String
    let values: [String]
    
    init(key: String, description: String, values: [String]) {
        self.key = key
        self.description = description
        self.values = values
    }
}
