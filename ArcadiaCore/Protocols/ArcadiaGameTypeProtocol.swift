//
//  ArcadiaGameTypeProtocol.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 18/05/24.
//

import Foundation
import UniformTypeIdentifiers

public protocol ArcadiaGameTypeProtocol {
    var allowedExtensions: [UTType] {get}
    var associatedCore: any ArcadiaCoreProtocol {get}
    var saveFileExtension: String  {get}
    var id: Self {get}
    
}
