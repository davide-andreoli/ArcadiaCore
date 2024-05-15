//
//  iRetroAudioVideoInfo.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public protocol iRetroAudioVideoInfoProtocol {
    associatedtype iRetroGeometryType: iRetroGameGeometryProtocol
    associatedtype iRetroTimingType: iRetroSystemTimingProtocol
    
    var geometry: iRetroGeometryType { get set }
    var timing: iRetroTimingType { get set }
    
    init(geometry: iRetroGeometryType, timing: iRetroTimingType)
}
