//
//  iRetroCore.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 01/05/24.
//

import Foundation
import CoreGraphics

public protocol ArcadiaVariableProtocol {
    var key: UnsafePointer<CChar>! { get set }
    var value: UnsafePointer<CChar>! { get set }
}

public protocol ArcadiaCoreProtocol {
    
    associatedtype ArcadiaCoreType: ArcadiaCoreProtocol
    associatedtype ArcadiaGameInfo: ArcadiaGameInfoProtocol
    associatedtype ArcadiaAudioVideoInfoType: ArcadiaAudioVideoInfoProtocol
    associatedtype ArcadiaGameGeometryType: ArcadiaGameGeometryProtocol
    associatedtype ArcadiaSystemTimingType: ArcadiaSystemTimingProtocol
    associatedtype ArcadiaVariableType: ArcadiaVariableProtocol
    
    static var sharedInstance: ArcadiaCoreType { get set }
    
    var paused: Bool {get set}
    var initialized: Bool {get set}
    var mainGameLoop : Timer? {get set}
    var loadedGame: URL? {get set}
    
    var audioVideoInfo: ArcadiaAudioVideoInfoType {get set}
    var pitch: Int {get set}

    
    // Libretro Callbacks
    var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {get}
    var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {get}
    var libretroAudioSampleCallback: @convention(c) (Int16, Int16) -> Void {get}
    var libretroAudioSampleBatchCallback: @convention(c) (UnsafePointer<Int16>?, Int) -> Int {get}
    var libretroInputPollCallback: @convention(c) () -> Void {get}
    var libretroInputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16 {get}
    
    // Libretro API Interfaces - To be implemented by the core
    func retroInit()
    func retroGetSystemAVInfo(info: UnsafeMutablePointer<ArcadiaAudioVideoInfoType>!)
    func retroDeinit()
    func retroRun()
    func retroLoadGame(gameInfo: ArcadiaGameInfo)
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
    
    // Frontend/Complex interfaces
    func setInputOutputCallbacks()
    mutating func initializeCore()
    mutating func deinitializeCore()
    mutating func getSystemAVInfo()
    mutating func loadGame(gameURL: URL)
    mutating func unloadGame()
    func saveState(saveFileURL: URL)
    func loadState(saveFileURL: URL)
    
    mutating func pressButton(button: ArcadiaCoreButton)
    func startGameLoop()
    func stopGameLoop()
    mutating func pauseGame()
    mutating func resumeGame()
    
}

enum ArcadiaCallbackType: UInt32 {
    case SET_ROTATION = 1
    case GET_OVERSCAN = 2
    case GET_CAN_DUPE = 3
    case SET_MESSAGE = 6
    case SHUTDOWN = 7
    case SET_PERFORMANCE_LEVEL = 8
    case GET_SYSTEM_DIRECTORY = 9
    case PIXEL_FORMAT = 10
    case SET_INPUT_DESCRIPTORS = 11
    case GET_VARIABLE = 15
    case SET_VARIABLES = 16
    case GET_VARIABLE_UPDATE = 17
    case GET_RUMBLE_INTERFACE = 23
    case GET_LOG_INTERFACE = 27
    case GET_CORE_OPTIONS_VERSION = 52
    case GET_MESSAGE_INTERFACE_VERSION = 59
    case SET_FASTFORWARDING_OVERRIDE = 64
    case SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK = 69
    case SET_VARIABLE = 70

}




// Libretro Callbacks
extension ArcadiaCoreProtocol {
    
    
    public var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {
        return {command, data in
            if let arcadiaCommand = ArcadiaCallbackType(rawValue: command) {
                print(arcadiaCommand)
            } else {
                print("Unknown \(command)")
            }
            switch command {
            case 3:
                data?.storeBytes(of: true, as: Bool.self)
                return true
            case 10:
                ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat = ArcadiaCorePixelType(rawValue: data!.load(as: UInt32.self))
                return true
            case 15:
                // Define your custom key and value
                let customKey = "gambatte_gbc_color_correction"
                let customValue = "disabled"
                
                // Convert Swift String to C-style string
                let keyCString = strdup(customKey)
                let valueCString = strdup(customValue)
                
                // Create retro_variable struct
                var customVariable = retro_variable(key: keyCString, value: valueCString)
                
                // Allocate memory for retro_variable struct
                let variableSize = MemoryLayout<retro_variable>.size
                let variablePointer = UnsafeMutableRawPointer.allocate(byteCount: variableSize, alignment: 1)
                
                // Copy customVariable into memory
                variablePointer.initializeMemory(as: retro_variable.self, from: &customVariable, count: 1)
                
                // Set the data parameter to point to the loaded retro_variable struct
                data?.storeBytes(of: variablePointer, as: UnsafeMutableRawPointer?.self)
                
                // Free allocated C-style strings
                free(keyCString)
                free(valueCString)
                
                return true
            case 16:
                // Assuming data contains an array of retro_variable structs
                // terminated by a { NULL, NULL } element
                var variables: [retro_variable] = []
                let pointer = data!.bindMemory(to: retro_variable.self, capacity: 1)
                var index = 0
                while pointer[index].key != nil {
                    variables.append(pointer[index])
                    index += 1
                }
                // Now you have an array of retro_variable structs, you can work with it here
                // For example, iterate over variables and print key-value pairs
                for variable in variables {
                    guard let key = variable.key else { continue }
                    guard let value = variable.value else { continue }
                    print("Key: \(String(cString: key)), Value: \(String(cString: value))")
                }
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
                    
                    let endianness = CFByteOrderGetCurrent()
                    var red: UInt8 = 0
                    var green: UInt8 = 0
                    var blue: UInt8 = 0
                    var alpha: UInt8 = 0
                    
                    if ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat == .pixelFormatXRGB8888 {
                        if endianness == CFByteOrderLittleEndian.rawValue {
                            blue = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
                            green = frameBufferPtr.load(fromByteOffset: pixelOffset + 1, as: UInt8.self)
                            red = frameBufferPtr.load(fromByteOffset: pixelOffset + 2, as: UInt8.self)
                            alpha = frameBufferPtr.load(fromByteOffset: pixelOffset + 3, as: UInt8.self)
                        } else if endianness == CFByteOrderBigEndian.rawValue {
                            blue = frameBufferPtr.load(fromByteOffset: pixelOffset + 2, as: UInt8.self)
                            green = frameBufferPtr.load(fromByteOffset: pixelOffset + 1, as: UInt8.self)
                            red = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
                            alpha = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
                        } else {
                            print( "unknown")
                        }

                        pixelArray[rgbaOffset] = blue
                        pixelArray[rgbaOffset + 1] = green
                        pixelArray[rgbaOffset + 2] = red
                        pixelArray[rgbaOffset + 3] = alpha
                    
                    }
                }
                
            }
            ArcadiaCoreEmulationState.sharedInstance.mainBuffer = pixelArray
            
                      
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
            ArcadiaCoreEmulationState.sharedInstance.currentAudioFrame = audioSlice
            
            return frames
        }
    }
    
    public var libretroInputPollCallback: @convention(c) () -> Void {
        return {
            //print("input poll")
        }
    }
    
    public var libretroInputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16 {
        return {port,device,index,id in

            if !ArcadiaCoreEmulationState.sharedInstance.buttonsPressed.isEmpty {
                if ArcadiaCoreEmulationState.sharedInstance.buttonsPressed[0] == Int(id) {
                    ArcadiaCoreEmulationState.sharedInstance.buttonsPressed.remove(at: 0)
                    return Int16(1)
                }
            }
            return Int16(0)
        }
    }
    

    
}

// Frontend/Complex interfaces
extension ArcadiaCoreProtocol {
    public func setInputOutputCallbacks() {
        retroSetVideoRefresh(videoRefreshCallback: libretroVideoRefreshCallback)
        retroSetAudioSample(audioSampleCallback: libretroAudioSampleCallback)
        retroSetAudioSampleBatch(audioSampleBatchCallback: libretroAudioSampleBatchCallback)
        retroSetInputPoll(inputPollCallback: libretroInputPollCallback)
        retroSetInputState(inputStateCallback: libretroInputStateCallback)
    }
    
    mutating public func getSystemAVInfo() {
        var avInfo = ArcadiaAudioVideoInfoType(geometry: ArcadiaGameGeometryType(base_width: 0, base_height: 0, max_width: 0, max_height: 0, aspect_ratio: 0.0) as! Self.ArcadiaAudioVideoInfoType.ArcadiaGeometryType,
                                              timing: ArcadiaSystemTimingType(fps: 0.0, sample_rate: 0.0) as! Self.ArcadiaAudioVideoInfoType.ArcadiaTimingType)
        retroGetSystemAVInfo(info: &avInfo)
        ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo = ArcadiaAudioVideoInfo(avInfo: avInfo)
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
    
    mutating public func deinitializeCore() {
        if initialized == true {
            retroDeinit()
            initialized = false
        }
    }
    
    mutating public func loadGame(gameURL: URL) {
        self.loadedGame = gameURL
        ArcadiaCoreEmulationState.sharedInstance.currentGameURL = gameURL
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
        
        var rom_info = ArcadiaGameInfo(path: romNameCptr, data: data, size: romFile!.count, meta: nil)
        retroLoadGame(gameInfo: rom_info)
        
    }
    
    mutating public func unloadGame() {
        ArcadiaCoreEmulationState.sharedInstance.currentGameURL = nil
        //TODO: empty the button pressed array
        retroUnloadGame()
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

extension ArcadiaCoreProtocol {
    mutating public func pressButton(button: ArcadiaCoreButton) {
        ArcadiaCoreEmulationState.sharedInstance.buttonsPressed.append(button.rawValue)
    
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

