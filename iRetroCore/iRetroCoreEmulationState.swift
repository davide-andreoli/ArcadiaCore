//
//  iRetroCoreEmulationState.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation
import CoreGraphics
import QuartzCore

@Observable public class iRetroCoreEmulationState {
    
    public static var sharedInstance = iRetroCoreEmulationState()
    
    public var audioVideoInfo: iRetroAudioVideoInfo? = nil
    public var mainBuffer = [UInt8]()
    public var mainBufferPixelFormat: iRetroCorePixelType = .pixelFormatXRGB8888
    public var currentFrame : CGImage? = nil
    public var buttonsPressed : [Int16] = []
    public var currentAudioFrame = [Int16]()
    public var currentGameURL: URL? = nil
    
    public var mainGameLoop : Timer? = nil
    public var paused = false
    
    //TODO: Should the current state keep track of current game state (paused, etc?)
    //TODO: Should the current state contain the main timer (or display link) and let the core attach the relevant loop when needed?
    
    func createCGImage(pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        
        let numBytes = pixels.count
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        
        guard let rgbData = CFDataCreate(nil, pixels, numBytes) else {
            return nil
        }
        
        guard let provider = CGDataProvider(data: rgbData) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bytesPerPixel * bitsPerComponent,
            bytesPerRow: width * bytesPerPixel,
            space: colorspace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue), // Skip the first byte (alpha)
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent)
    }
    
}
