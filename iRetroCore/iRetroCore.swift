//
//  iRetroCore.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 01/05/24.
//

import Foundation
import CoreGraphics


public protocol iRetroGameGeometry {
    var base_width: UInt32 { get set }
    var base_height: UInt32 { get set }
    var max_width: UInt32 { get set }
    var max_height: UInt32 { get set }
    var aspect_ratio: Float { get set }
    
    init(base_width: UInt32, base_height: UInt32, max_width: UInt32, max_height: UInt32, aspect_ratio: Float)
}

public protocol iRetroSystemTiming {
    var fps: Double { get set }
    var sample_rate: Double { get set }
    
    init(fps: Double, sample_rate: Double)
}

public protocol iRetroAudioVideoInfo {
    associatedtype iRetroGeometryType: iRetroGameGeometry
    associatedtype iRetroTimingType: iRetroSystemTiming
    
    var geometry: iRetroGeometryType { get set }
    var timing: iRetroTimingType { get set }
    
    init(geometry: iRetroGeometryType, timing: iRetroTimingType)
}

public protocol iRetroGameInfoProtocol {
    var path: UnsafePointer<CChar>! { get set }
    var data: UnsafeRawPointer! { get set }
    var size: Int { get set }
    var meta: UnsafePointer<CChar>! { get set }
    
    init(path: UnsafePointer<CChar>!, data: UnsafeRawPointer!, size: Int, meta: UnsafePointer<CChar>!)
}


public protocol iRetroCoreProtocol {
    
    associatedtype iRetroCoreType: iRetroCoreProtocol
    associatedtype iRetroGameInfo: iRetroGameInfoProtocol
    associatedtype iRetroAudioVideoInfoType: iRetroAudioVideoInfo
    associatedtype iRetroGameGeometryType: iRetroGameGeometry
    associatedtype iRetroSystemTimingType: iRetroSystemTiming
    
    static var sharedInstance: iRetroCoreType { get set }
    
    var paused: Bool {get set}
    var initialized: Bool {get set}
    var mainGameLoop : Timer? {get set}
    var loadedGame: URL? {get set}
    
    var audioVideoInfo: iRetroAudioVideoInfoType {get set}
    var pitch: Int {get set}
    var mainBuffer: [UInt8] {get set}
    var currentFrame: CGImage? { get set }
    var buttonsPressed : [Int16] { get set }
    var currentAudioFrame: [Int16] {get set}
    
    var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {get}
    var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {get}
    var libretroAudioSampleCallback: @convention(c) (Int16, Int16) -> Void {get}
    var libretroAudioSampleBatchCallback: @convention(c) (UnsafePointer<Int16>?, Int) -> Int {get}
    var libretroInputPollCallback: @convention(c) () -> Void {get}
    var libretroInputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16 {get}
    
    func retroInit()
    func retroGetSystemAVInfo(info: UnsafeMutablePointer<iRetroAudioVideoInfoType>!)
    func retroDeinit()
    func retroRun()
    func retroLoadGame(gameInfo: iRetroGameInfo)
    func retroUnloadGame()
    func retroSerializeSize() -> Int
    func retroSerialize(data: UnsafeMutableRawPointer!, size: Int)
    func retroUnserialize(data: UnsafeRawPointer!, size: Int)
    func retroSetEnvironment(environmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool)
    func retroSetVideoRefresh(videoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void)
    func retroSetAudioSample(audioSampleCallback: @convention(c) (Int16, Int16) -> Void)
    func retroSetAudioSampleBatch(audioSampleBatchCallback: @convention(c) (UnsafePointer<Int16>?, Int) -> Int)
    func retroSetInputPoll(inputPollCallback: @convention(c) () -> Void)
    func retroSetInputState(inputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16)
    
    func setInputOutputCallbacks()
    mutating func initializeCore()
    mutating func getSystemAVInfo()
    mutating func loadGame(gameURL: URL)
    func saveState(saveFileURL: URL)
    func loadState(saveFileURL: URL)
    
    mutating func pressButton(button: iRetroCoreButton)
    func startGameLoop()
    func stopGameLoop()
    mutating func pauseGame()
    mutating func resumeGame()
    
}

public enum iRetroCorePixelType: UInt32 {
    case RGB1555 = 0
    case XRGB8888 = 1
    case RGB565 = 2
}

public enum iRetroCoreButton: Int16 {
    case joypadB = 0
    case joypadY = 1
    case joypadSelect = 2
    case joypadStart = 3
    case joypadUp = 4
    case joypadDown = 5
    case joypadLeft = 6
    case joypadRight = 7
    case joypadA = 8
    case joypadX = 9
    case joypadL = 10
    case joypadR = 11
    case joypadL2 = 12
    case joypadR2 = 13
    case joypadL3 = 14
    case joypadR3 = 15
}

extension iRetroCoreProtocol {
    
    
    public var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {
        return {command, data in
            switch command {
            case 3:
                data?.storeBytes(of: true, as: Bool.self)
                return true
            case 10:
                //let format = retro_pixel_format(rawValue: data!.load(as: UInt32.self))
                print("Environment Pixel format set as \(data!.load(as: UInt32.self))")
                return true
            default:
                return false
            }
        }
    }
    
    public var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {
        return {frameBufferData, width, height, pitch  in
            
            guard let frameBufferPtr = frameBufferData else {
                print("frame_buffer_data was null")
                return
            }
                     
            let height = Int(height)
            let width = Int(width)
            let pitch = pitch

            let bytesPerPixel = 4 // Assuming XRGB8888 format
            let lengthOfFrameBuffer = height * pitch // 294912

            var pixelArray = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
            
            for y in 0..<height {
                let rowOffset = y * pitch
                for x in 0..<width {
                    let pixelOffset = rowOffset + x * bytesPerPixel * 2 //TODO: Understand why I need to multiply this by two
                    let rgbaOffset = y * width * bytesPerPixel + x * bytesPerPixel

                    // Assuming XRGB8888 format where each pixel is 4 bytes
                    let blue = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
                    let green = frameBufferPtr.load(fromByteOffset: pixelOffset + 1, as: UInt8.self)
                    let red = frameBufferPtr.load(fromByteOffset: pixelOffset + 2, as: UInt8.self)
                    let alpha = frameBufferPtr.load(fromByteOffset: pixelOffset + 3, as: UInt8.self)


                    pixelArray[rgbaOffset] = alpha
                    pixelArray[rgbaOffset + 1] = red
                    pixelArray[rgbaOffset + 2] = green
                    pixelArray[rgbaOffset + 3] = blue
                }
            }
            
            iRetroCoreEmulationState.sharedInstance.mainBuffer = pixelArray
            iRetroCoreEmulationState.sharedInstance.currentFrame = createCGImageFromXRGB8888(pixels: pixelArray, width: Int(width), height: Int(height))
                      
        }
    }
    
    public var libretroAudioSampleCallback: @convention(c) (Int16, Int16) -> Void {
        return {left,right  in
            print("libretro_set_audio_sample_callback left channel: \(left) right: \(right)")
        }
    }
    
    public var libretroAudioSampleBatchCallback: @convention(c) (UnsafePointer<Int16>?, Int) -> Int {
        return {data,frames  in
            guard let audioData = data else { return 0 }

            let audioBuffer = UnsafeBufferPointer(start: audioData, count: frames * 2)
            let audioSlice = Array(audioBuffer)
            //let audioSliceData = Data(bytes: audioSlice, count: audioSlice.count * MemoryLayout<Int16>.size)
            iRetroCoreEmulationState.sharedInstance.currentAudioFrame = audioSlice
            
            return frames
        }
    }
    
    public var libretroInputPollCallback: @convention(c) () -> Void {
        return {
            print("input poll")
        }
    }
    
    public var libretroInputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16 {
        return {port,device,index,id in

            if !iRetroCoreEmulationState.sharedInstance.buttonsPressed.isEmpty {
                if iRetroCoreEmulationState.sharedInstance.buttonsPressed[0] == Int(id) {
                    iRetroCoreEmulationState.sharedInstance.buttonsPressed.remove(at: 0)
                    return Int16(1)
                }
            }
            return Int16(0)
        }
    }
    

    
}

extension iRetroCoreProtocol {
    public func setInputOutputCallbacks() {
        retroSetVideoRefresh(videoRefreshCallback: libretroVideoRefreshCallback)
        retroSetAudioSample(audioSampleCallback: libretroAudioSampleCallback)
        retroSetAudioSampleBatch(audioSampleBatchCallback: libretroAudioSampleBatchCallback)
        retroSetInputPoll(inputPollCallback: libretroInputPollCallback)
        retroSetInputState(inputStateCallback: libretroInputStateCallback)
    }
    
    mutating public func getSystemAVInfo() {
        //TODO: Understand if it makes senso to add it to Emulator State
        var avInfo = iRetroAudioVideoInfoType(geometry: iRetroGameGeometryType(base_width: 0, base_height: 0, max_width: 0, max_height: 0, aspect_ratio: 0.0) as! Self.iRetroAudioVideoInfoType.iRetroGeometryType,
                                              timing: iRetroSystemTimingType(fps: 0.0, sample_rate: 0.0) as! Self.iRetroAudioVideoInfoType.iRetroTimingType)
        retroGetSystemAVInfo(info: &avInfo)
        self.audioVideoInfo = avInfo
    }
    
    mutating public func initializeCore() {
        if initialized == false {
            retroSetEnvironment(environmentCallback: libretroEnvironmentCallback)
            retroInit()
            getSystemAVInfo()
            initialized = true
        }
    }
    
    mutating public func loadGame(gameURL: URL) {
        self.loadedGame = gameURL
        var filepath = gameURL.absoluteString
        gameURL.startAccessingSecurityScopedResource()
        var location = filepath.cString(using: String.Encoding.utf8)!

        
        let romNameCstr = (filepath as NSString).utf8String
        let romNameCptr = UnsafePointer<CChar>(romNameCstr)
        
        var data: UnsafeRawPointer? = nil
        var romFile: Data? = nil
        
        let contents = FileManager.default.contents(atPath: filepath)
        do {
            romFile = try Data(contentsOf: gameURL)
            guard let romFile = romFile else {
                fatalError("Failed to read file")
            }
            data = romFile.withUnsafeBytes({ $0.baseAddress })
        }
        catch {
            fatalError("Failed to read file")
        }
        
        gameURL.stopAccessingSecurityScopedResource()
        
        var rom_info = iRetroGameInfo(path: romNameCptr, data: data, size: romFile!.count, meta: nil)
        retroLoadGame(gameInfo: rom_info)
        
    }
    
    public func saveState(saveFileURL: URL) {
        let stateSize = retroSerializeSize()
        var stateBuffer = [UInt8](repeating: 0, count: stateSize)
        
        stateBuffer.withUnsafeMutableBytes { bufferPointer in
            if let baseAddress = bufferPointer.baseAddress {
                retroSerialize(data: baseAddress, size: stateSize)
            }
        }
        
        do {
            try Data(stateBuffer).write(to: saveFileURL)
        } catch {
            print("Error writing save state: \(error)")
        }
    }
    
    public func loadState(saveFileURL: URL) {
        do {
            var saveFileContent = try Data(contentsOf: saveFileURL)
            saveFileContent.withUnsafeBytes { pointer in
                if let baseAddress = pointer.baseAddress {
                    retroUnserialize(data: baseAddress, size: saveFileContent.count)
                }
            }
        }
        catch {
            print("Error writing save state: \(error)")
        }
    }
    
}

extension iRetroCoreProtocol {
    mutating public func pressButton(button: iRetroCoreButton) {
        self.buttonsPressed.append(button.rawValue)
        iRetroCoreEmulationState.sharedInstance.buttonsPressed.append(button.rawValue)
    
    }
    
    mutating public func pauseGame() {
        self.paused = true
    }
    
    mutating public func resumeGame() {
        self.paused = false
    }
}


public func createCGImageFromXRGB8888(pixels: [UInt8], width: Int, height: Int) -> CGImage? {
    
    let numBytes = pixels.count
    let bytesPerPixel = 4 // Each pixel is represented by 4 bytes in XRGB8888 format
    let numComponents = 3 // XRGB format has three components per pixel (Red, Green, Blue)
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

public func callbackOutputToPixelBuffer(frameBufferData: UnsafeRawPointer?, width: UInt32, height: UInt32, pitch: Int) -> [UInt8] {
    guard let frameBufferPtr = frameBufferData else {
        print("frame_buffer_data was null")
        return []
    }
             
    let height = Int(height)
    let width = Int(width)
    let pitch = pitch

    let bytesPerPixel = 4 // Assuming XRGB8888 format
    let lengthOfFrameBuffer = height * pitch // 294912

    var pixelArray = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    for y in 0..<height {
        let rowOffset = y * pitch
        for x in 0..<width {
            let pixelOffset = rowOffset + x * bytesPerPixel * 2 //TODO: Understand why I need to multiply this by two
            let rgbaOffset = y * width * bytesPerPixel + x * bytesPerPixel

            // Assuming XRGB8888 format where each pixel is 4 bytes
            let blue = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
            let green = frameBufferPtr.load(fromByteOffset: pixelOffset + 1, as: UInt8.self)
            let red = frameBufferPtr.load(fromByteOffset: pixelOffset + 2, as: UInt8.self)
            let alpha = frameBufferPtr.load(fromByteOffset: pixelOffset + 3, as: UInt8.self)


            pixelArray[rgbaOffset] = alpha
            pixelArray[rgbaOffset + 1] = red
            pixelArray[rgbaOffset + 2] = green
            pixelArray[rgbaOffset + 3] = blue
        }
    }
    
    return pixelArray
}
