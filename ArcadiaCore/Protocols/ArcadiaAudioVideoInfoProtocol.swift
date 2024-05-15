//
//  iRetroAudioVideoInfo.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public protocol ArcadiaAudioVideoInfoProtocol {
    associatedtype ArcadiaGeometryType: ArcadiaGameGeometryProtocol
    associatedtype ArcadiaTimingType: ArcadiaSystemTimingProtocol
    
    var geometry: ArcadiaGeometryType { get set }
    var timing: ArcadiaTimingType { get set }
    
    init(geometry: ArcadiaGeometryType, timing: ArcadiaTimingType)
}
