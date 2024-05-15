//
//  iRetroGameGeometry.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public protocol iRetroGameGeometryProtocol {
    var base_width: UInt32 { get set }
    var base_height: UInt32 { get set }
    var max_width: UInt32 { get set }
    var max_height: UInt32 { get set }
    var aspect_ratio: Float { get set }
    
    init(base_width: UInt32, base_height: UInt32, max_width: UInt32, max_height: UInt32, aspect_ratio: Float)
}
