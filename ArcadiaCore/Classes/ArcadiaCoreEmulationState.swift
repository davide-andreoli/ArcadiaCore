//
//  iRetroCoreEmulationState.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation
import CoreGraphics
import QuartzCore
import MetalKit

@Observable public class ArcadiaCoreEmulationState {
    
    public static var sharedInstance = ArcadiaCoreEmulationState()
    public var audioPlayer = ArcadiaCoreAudioPlayer()
    public var metalRendered = ArcadiaCoreMetalRenderer()
    public var lastImage: CGImage? {
        // Ensure the metalRendered texture is valid
        guard let texture = metalRendered.texture else {
            print("Texture not available")
            return nil
        }
                
        // Create a CIImage from the Metal texture
        guard let image = CIImage(mtlTexture: texture, options: nil) else {
            print("Failed to create CIImage from Metal texture")
            return nil
        }
        
        // Flip the image vertically
        let flipped = image.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
        
        // Ensure the color space matches the texture's color space
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            print("Failed to create color space")
            return nil
        }
        
        // Create a CGImage from the CIImage
        guard let cgImage = CIContext().createCGImage(flipped, from: flipped.extent, format: .RGBA8, colorSpace: colorSpace) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }
        
        // Log the success and the size of the CGImage
        print("Returning image \(cgImage.width) x \(cgImage.height)")
        return cgImage
    }


    
    public var audioVideoInfo: retro_system_av_info? = nil
    public var mainBuffer = [UInt8]()
    public var mainBufferPixelFormat: ArcadiaCorePixelType = .pixelFormatXRGB8888
    public var showOverlay: Bool = false
    public var currentFrame : CGImage? {
        get {
            return createCGImage(pixels: mainBuffer, width: Int(audioVideoInfo?.geometry.base_width ?? 0), height: Int(audioVideoInfo?.geometry.base_height ?? 0))
        }
        set (newValue) {
            // Just for binding
        }
    }
    
    public var currentCore: (any ArcadiaCoreProtocol)? = nil
    public var currentGameType: (any ArcadiaGameTypeProtocol)? = nil
    public var coreOptionsToApply: [ArcadiaCoreOption] = []
    
    public var pressedButtons: [UInt32 : [UInt32 : [UInt32 : [UInt32 : Int16]]]] = [:]
    public var currentAudioFrameFloat = [Float]()
    public var currentGameURL: URL? = nil

    public var currentSaveFileURL: [ArcadiaCoreMemoryType: URL] = [:]
    public var currentStateURL: [Int : URL] = [:]
    
    public var currentCoreOptions: [ArcadiaCoreOption] = []
    
    public var mainGameLoop : Timer? = nil
    public var checkSaveLoop: DispatchSourceTimer? = nil
    public var gameLoopTimer: DispatchSourceTimer? = nil
    public var paused = false
    
    public func attachCore(core: any ArcadiaCoreProtocol) {
        if self.currentCore == nil {
            self.currentCore = core
        } else {
            if type(of: self.currentCore) == type(of: core) {
                return
            } else {
                self.currentCore = core
            }
        }
    }
    

            
    public func startGameLoop() {
        let gameLoopQueue = DispatchQueue(label: "com.Arcadia.gameLoop")
        if gameLoopTimer == nil {
            gameLoopTimer = DispatchSource.makeTimerSource(queue: gameLoopQueue)
            gameLoopTimer?.schedule(deadline: .now(), repeating: 1.0 / 60.0)
            gameLoopTimer?.setEventHandler { [weak self] in
                self?.gameLoop()
            }
            gameLoopTimer?.resume()
            startSaveRamMonitoring()
            paused = false
        }
    }
    
    
    public func stopGameLoop() {
        gameLoopTimer?.cancel()
        gameLoopTimer = nil
        stopSaveRamMonitoring()
        paused = true
    }
    
    
    @objc func gameLoop() {
        if !paused {
            self.currentCore?.retroRun()
        }
    }
    /*
     main thread game loop
     public func startGameLoop() {
         mainGameLoop = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(gameLoop), userInfo: nil, repeats: true)
         RunLoop.current.add(mainGameLoop!, forMode: .default)
         startSaveRamMonitoring()
         paused = false
     }
     
     public func stopGameLoop() {
         mainGameLoop?.invalidate()
         mainGameLoop = nil
         stopSaveRamMonitoring()
         paused = true
     }
     
     
     @objc func gameLoop() {
         if !paused {
             self.currentCore?.retroRun()
         }
     }
     */
    
    func startSaveRamMonitoring() {
        let queue = DispatchQueue(label: "com.Arcadia.saveRamMonitoringQueue", qos: .background)
        
        self.checkSaveLoop = DispatchSource.makeTimerSource(queue: queue)
        self.checkSaveLoop?.schedule(deadline: .now(), repeating: 1)
        self.checkSaveLoop?.setEventHandler { [weak self] in
            guard let self = self else { return }
            if !paused {
                for memoryType in currentGameType!.supportedSaveFiles.keys {
                    guard let checkResult = self.currentCore?.checkForSaveRamModification(memoryDataId: memoryType.rawValue) else {
                        return
                    }
                        if checkResult {
                            self.currentCore?.saveMemoryData(memoryId: memoryType.rawValue, saveFileURL: (ArcadiaCoreEmulationState.sharedInstance.currentSaveFileURL[memoryType])!)
                        }
                    
                    }
                }
        }
        self.checkSaveLoop?.resume()
    }
    
    func stopSaveRamMonitoring() {
        self.checkSaveLoop?.cancel()
        self.checkSaveLoop = nil
    }
    
    public func prepareCore(gameURL: URL, gameType: any ArcadiaGameTypeProtocol, stateURLs: [Int: URL], saveFileURLs: [ArcadiaCoreMemoryType : URL]) {
        if gameType.name != currentGameType?.name {
            self.currentCore?.deinitializeCore()
            self.currentCore = nil
            self.currentGameType = gameType
            self.attachCore(core: gameType.associatedCore)
            self.currentCore?.initializeCore()
            self.currentCore?.setInputOutputCallbacks()
        }
        self.currentStateURL = stateURLs
        self.currentSaveFileURL = saveFileURLs
        self.coreOptionsToApply.append(contentsOf: self.currentCore!.defaultCoreOptions)
        self.currentCore?.loadGame(gameURL: gameURL)
        for memoryType in gameType.supportedSaveFiles.keys {
            if FileManager.default.fileExists(atPath: self.currentSaveFileURL[memoryType]?.path ?? "") {
                self.currentCore?.loadBatterySave(from: self.currentSaveFileURL[memoryType]!, memoryDataId: memoryType.rawValue)
            }
            else {
                self.currentCore?.saveMemoryData(memoryId: memoryType.rawValue, saveFileURL: (self.currentSaveFileURL[memoryType])!)
                self.currentCore?.takeInitialSaveRamSnapshot(memoryDataId: memoryType.rawValue)
            }
            
        }
        
    }
    
    public func startEmulation(gameURL: URL, gameType: any ArcadiaGameTypeProtocol, stateURLs: [Int : URL], saveFileURLs: [ArcadiaCoreMemoryType : URL]) {
        if self.currentGameURL != nil {
            if self.currentGameURL == gameURL {
                self.resumeEmulation()
            } else {
                self.stopGameLoop()
                self.currentCore?.unloadGame()
                self.prepareCore(gameURL: gameURL, gameType: gameType, stateURLs: stateURLs, saveFileURLs: saveFileURLs)
                self.startGameLoop()
                //TODO: check if current audio player sample rate is ok or it needs to change
                if self.audioPlayer.sampleRate != self.currentCore?.audioVideoInfo.timing.sample_rate {
                    print("Changing sample rate")
                    self.audioPlayer.changeSampleRate(to: self.currentCore!.audioVideoInfo.timing.sample_rate)
                }
                self.audioPlayer.start()
            }
        } else {
            self.prepareCore(gameURL: gameURL, gameType: gameType, stateURLs: stateURLs, saveFileURLs: saveFileURLs)
            self.startGameLoop()
            if self.audioPlayer.sampleRate != self.currentCore?.audioVideoInfo.timing.sample_rate {
                print("Changing sample rate")
                self.audioPlayer.changeSampleRate(to: self.currentCore!.audioVideoInfo.timing.sample_rate)
            }
            self.audioPlayer.start()
        }
    }
    
    public func startEmulation(gameURL: URL) {
        if self.currentGameURL != nil {
            if self.currentGameURL == gameURL {
                self.resumeEmulation()
            } else {
                self.stopGameLoop()
                self.currentCore?.unloadGame()
                //TODO: Understand if it's really necessary to deinit the core
                self.currentCore?.deinitializeCore()
                self.currentCore?.initializeCore()
                self.currentCore?.loadGame(gameURL: gameURL)
                for memoryType in currentGameType!.supportedSaveFiles.keys {
                    if FileManager.default.fileExists(atPath: self.currentSaveFileURL[memoryType]?.path ?? "") {
                        self.currentCore?.loadBatterySave(from: self.currentSaveFileURL[memoryType]!, memoryDataId: memoryType.rawValue)
                    }
                    else {
                        self.currentCore?.saveMemoryData(memoryId: memoryType.rawValue, saveFileURL: (self.currentSaveFileURL[memoryType])!)
                        self.currentCore?.takeInitialSaveRamSnapshot(memoryDataId: memoryType.rawValue)
                    }
                    
                    }
                self.currentCore?.setInputOutputCallbacks()
                self.startGameLoop()
                self.audioPlayer.start()
            }
        } else {
            self.currentCore?.initializeCore()
            self.currentCore?.loadGame(gameURL: gameURL)
            for memoryType in currentGameType!.supportedSaveFiles.keys {
                if FileManager.default.fileExists(atPath: self.currentSaveFileURL[memoryType]?.path ?? "") {
                    print("Found file in \(self.currentSaveFileURL[memoryType]!.path)")
                    self.currentCore?.loadBatterySave(from: self.currentSaveFileURL[memoryType]!, memoryDataId: memoryType.rawValue)
                }
                else {
                    self.currentCore?.saveMemoryData(memoryId: memoryType.rawValue, saveFileURL: (self.currentSaveFileURL[memoryType])!)
                    self.currentCore?.takeInitialSaveRamSnapshot(memoryDataId: memoryType.rawValue)
                }
                
                }
            self.currentCore?.setInputOutputCallbacks()
            self.startGameLoop()
            self.audioPlayer.start()
        }
    }
    
    public func pauseEmulation () {
        self.paused = true
    }
    
    public func resumeEmulation () {
        self.paused = false
    }
    
    public func pressButton(port: UInt32, device: UInt32, index: UInt32, button id: ArcadiaCoreButton) {
        for buttonId in id.buttonsToPress {
            self.pressButton(port: port, device: device, index: index, button: buttonId)
        }
        
    }
    
    public func pressButton(port: UInt32, device: UInt32, index: UInt32, button id: UInt32) {
        if self.pressedButtons[port] == nil {
            self.pressedButtons[port] = [:]
        }
        if self.pressedButtons[port]?[device] == nil {
            self.pressedButtons[port]?[device] = [:]
        }
        
        if self.pressedButtons[port]?[device]?[0] == nil {
            self.pressedButtons[port]?[device]?[0] = [:]
        }
        if self.pressedButtons[port]?[device]?[0]?[id] == nil {
            self.pressedButtons[port]?[device]?[0]?[id] = Int16(1)
        }
        self.pressedButtons[port]?[device]?[index]?[id] = 1
    }
    
    public func unpressButton(port: UInt32, device: UInt32, index: UInt32, button id: UInt32) {
        self.pressedButtons[port]?[device]?[index]?[id] = 0
    }
    
    public func unpressButton(port: UInt32, device: UInt32, index: UInt32, button id: ArcadiaCoreButton) {
        for buttonId in id.buttonsToPress {
            self.unpressButton(port: port, device: device, index: index, button: buttonId)
        }
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
