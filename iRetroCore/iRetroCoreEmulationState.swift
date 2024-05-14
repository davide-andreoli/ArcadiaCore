//
//  iRetroCoreEmulationState.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation
import CoreGraphics

@Observable public class iRetroCoreEmulationState {
    
    public static var sharedInstance = iRetroCoreEmulationState()
    
    public var mainBuffer = [UInt8]()
    public var currentFrame : CGImage? = nil
    public var buttonsPressed : [Int16] = []
    public var currentAudioFrame = [Int16]()
    
}
