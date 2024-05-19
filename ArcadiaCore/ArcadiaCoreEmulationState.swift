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
    
    //TODO: the current core propery might be not useful now that the currentGameType can return the core
    public var currentCore: (any ArcadiaCoreProtocol)? = nil
    public var currentGameType: (any ArcadiaGameTypeProtocol)? = nil
    
    public var buttonsPressed : [Int16] = []
    public var currentAudioFrame = [Int16]()
    public var currentGameURL: URL? = nil

    public var currentSaveFolder: URL? = nil
    
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
        
    public func startGameLoop() {
        mainGameLoop = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(gameLoop), userInfo: nil, repeats: true)
        RunLoop.current.add(mainGameLoop!, forMode: .default)
        paused = false
    }
    
    public func stopGameLoop() {
        mainGameLoop?.invalidate()
        mainGameLoop = nil
        paused = true
    }
    
    
    @objc func gameLoop() {
        if !paused {
            self.currentCore?.retroRun()
            
            guard let checkResult = self.currentCore?.checkForSaveRamModification(memoryDataId: 0) else {
                return
            }
            if checkResult {
                print("Save File modified")
                self.currentCore?.saveMemoryData(memoryId: 0, saveFileURL: ArcadiaCoreEmulationState.sharedInstance.currentSaveFolder!)
            }
        }
    }
    
    public func startEmulation(gameURL: URL) {
        if self.currentGameURL != nil {
            if self.currentGameURL == gameURL {
                self.currentCore?.resumeGame()
            } else {
                self.stopGameLoop()
                self.currentCore?.unloadGame()
                //TODO: Understand if it's really necessary to deinit the core
                self.currentCore?.deinitializeCore()
                self.currentCore?.initializeCore()
                self.currentCore?.loadGame(gameURL: gameURL)
                if FileManager.default.fileExists(atPath: self.currentSaveFolder?.path ?? "") {
                    self.currentCore?.loadBatterySave(from: self.currentSaveFolder!, memoryDataId: 0)
                } else {
                    self.currentCore?.takeInitialSaveRamSnapshot(memoryDataId: 0)
                }
                self.currentCore?.setInputOutputCallbacks()
                self.startGameLoop()
            }
        } else {
            self.currentCore?.initializeCore()
            self.currentCore?.loadGame(gameURL: gameURL)
            if FileManager.default.fileExists(atPath: self.currentSaveFolder?.path ?? "") {
                self.currentCore?.loadBatterySave(from: self.currentSaveFolder!, memoryDataId: 0)
            } else {
                self.currentCore?.takeInitialSaveRamSnapshot(memoryDataId: 0)
            }
            self.currentCore?.setInputOutputCallbacks()
            self.startGameLoop()
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
