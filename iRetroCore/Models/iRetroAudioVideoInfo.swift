//
//  iRetroAudioVideoInfo.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public struct iRetroAudioVideoInfo: iRetroAudioVideoInfoProtocol {
    public typealias iRetroGeometryType = iRetroGeometry
    
    public typealias iRetroTimingType = iRetroSystemTiming
    
    public var geometry: iRetroGeometry
    
    public var timing: iRetroSystemTiming
    
    public init(geometry: iRetroGeometry, timing: iRetroSystemTiming) {
        self.geometry = geometry
        self.timing = timing
    }
    
}

public struct iRetroGeometry: iRetroGameGeometryProtocol {
    public var base_width: UInt32
    
    public var base_height: UInt32
    
    public var max_width: UInt32
    
    public var max_height: UInt32
    
    public var aspect_ratio: Float
    
    public init(base_width: UInt32, base_height: UInt32, max_width: UInt32, max_height: UInt32, aspect_ratio: Float) {
        self.base_width = base_width
        self.base_height = base_height
        self.max_width = max_width
        self.max_height = max_height
        self.aspect_ratio = aspect_ratio
    }
    
    public var width: Int {
        return Int(base_width)
    }
    
    public var height: Int {
        return Int(base_height)
    }
    
    public var aspectRatio: Double {
        return Double(aspect_ratio)
    }
    
    
}

public struct iRetroSystemTiming: iRetroSystemTimingProtocol {
    public var fps: Double
    
    public var sample_rate: Double
    
    public init(fps: Double, sample_rate: Double) {
        self.fps = fps
        self.sample_rate = sample_rate
    }
    
    
}


