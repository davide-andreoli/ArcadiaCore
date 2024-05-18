//
//  iRetroCoreEmulationState.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation
import CoreGraphics
import QuartzCore

@Observable public class ArcadiaCoreEmulationState {
    
    public static var sharedInstance = ArcadiaCoreEmulationState()
    
    public var audioVideoInfo: ArcadiaAudioVideoInfo? = nil
    public var mainBuffer = [UInt8]()
    public var mainBufferPixelFormat: ArcadiaCorePixelType = .pixelFormatXRGB8888
    public var currentFrame : CGImage? {
        get {
            return createCGImage(pixels: mainBuffer, width: audioVideoInfo?.geometry.width ?? 0, height: audioVideoInfo?.geometry.height ?? 0)
        }
        set (newValue) {
            // Just for binding
        }
    }
    
    public var currentCore: (any ArcadiaCoreProtocol)? = nil
    
    public var buttonsPressed : [Int16] = []
    public var currentAudioFrame = [Int16]()
    public var currentGameURL: URL? = nil
    
    public var currentCoreOptions: [ArcadiaCoreOption] = []
    
    public var mainGameLoop : Timer? = nil
    public var paused = false
    
    public func attachCore(core: any ArcadiaCoreProtocol) {
        if self.currentCore == nil {
            if type(of: self.currentCore) == type(of: core) {
                return
            } else {
                self.currentCore = core
            }
        }
    }
    
    //TODO: Should the current state keep track of current game state (paused, etc?)
    //TODO: Should the current state contain the main timer (or display link) and let the core attach the relevant loop when needed?
    
    public func startEmulation(gameURL: URL) {
        if self.currentGameURL != nil {
            print("1")
            if self.currentGameURL == gameURL {
                print("2")
                self.currentCore?.resumeGame()
            } else {
                self.currentCore?.stopGameLoop()
                self.currentCore?.unloadGame()
                //TODO: Understand if it's really necessary to deinit the core
                self.currentCore?.deinitializeCore()
                self.currentCore?.initializeCore()
                self.currentCore?.loadGame(gameURL: gameURL)
                self.currentCore?.setInputOutputCallbacks()
                self.currentCore?.startGameLoop()
            }
        } else {
            self.currentCore?.initializeCore()
            self.currentCore?.loadGame(gameURL: gameURL)
            self.currentCore?.setInputOutputCallbacks()
            self.currentCore?.startGameLoop()
        }
    }
    
    public func pauseEmulation () {
        self.currentCore?.pauseGame()
    }
    
    public func pressButton(button: ArcadiaCoreButton) {
        buttonsPressed.append(button.rawValue)
    }
    
    func createCGImage(pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        
        if width == 0 {
            return nil
        }
        
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
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        
       
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bytesPerPixel * bitsPerComponent,
            bytesPerRow: width * bytesPerPixel,
            space: colorspace,
            bitmapInfo: bitmapInfo, // Skip the last byte (alpha)
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent)
    }
    
}
