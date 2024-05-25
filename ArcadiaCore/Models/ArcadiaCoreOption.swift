//
//  ArcadiaCoreOptions.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 17/05/24.
//

import Foundation

public struct ArcadiaCoreOption: Hashable {
    public let key: String
    public let description: String
    public let values: [String]
    
    init(key: String, description: String, values: [String]) {
        self.key = key
        self.description = description
        self.values = values
    }
}
