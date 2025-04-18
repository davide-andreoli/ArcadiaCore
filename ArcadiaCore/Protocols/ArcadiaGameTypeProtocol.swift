//
//  ArcadiaGameTypeProtocol.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 18/05/24.
//

import Foundation
import UniformTypeIdentifiers

public protocol ArcadiaGameTypeProtocol {
    var name: String {get}
    var allowedExtensions: [UTType] {get}
    var associatedCore: any ArcadiaCoreProtocol {get}
    var saveFileExtension: String  {get}
    var supportedSaveFiles: [ArcadiaCoreMemoryType : String] {get}
    
    var getSaveDirectory: URL {get}
    var getStateDirectory: URL  {get}
    var getImageDirectory: URL  {get}
    var getCoreDirectory: URL  {get}
    
}

