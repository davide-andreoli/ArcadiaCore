//
//  iRetroSystemTiming.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public protocol ArcadiaSystemTimingProtocol {
    var fps: Double { get set }
    var sample_rate: Double { get set }
    
    init(fps: Double, sample_rate: Double)
}
