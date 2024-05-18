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
        
    var paused: Bool {get set}
    var initialized: Bool {get set}
    var mainGameLoop : Timer? {get set}
    var loadedGame: URL? {get set}
    
    var audioVideoInfo: ArcadiaAudioVideoInfoType {get set}

    
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
    func retroReset()
    func retroLoadGame(gameInfo: ArcadiaGameInfo)
    func retroUnloadGame()
    func retroSerializeSize() -> Int
    func retroSerialize(data: UnsafeMutableRawPointer!, size: Int)
    func retroUnserialize(data: UnsafeRawPointer!, size: Int)
    func retroGetMemorySize(memoryDataId: UInt32) -> Int
    func retroGetMemoryData(memoryDataId: UInt32) -> UnsafeMutableRawPointer!
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
    func saveMemoryData(memoryId: UInt32, saveFileURL: URL)
    func loadMemoryData(memoryId: UInt32)
    
    func startGameLoop()
    func stopGameLoop()
    mutating func pauseGame()
    mutating func resumeGame()
    
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
                // TODO: search for modified variables in the state and apply them
                /*
                // Define your custom key and value
                let customKey = "gearboy_palette"
                let customValue = "B/W"
                
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
                */
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

                for variable in variables {
                    guard let key = variable.key else { continue }
                    guard let value = variable.value else { continue }
                    print("Key: \(String(cString: key)), Value: \(String(cString: value))")
                    let components = String(cString: value).components(separatedBy: ";")
                    let description = components[0]
                    let values = components[1].components(separatedBy: "|").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    ArcadiaCoreEmulationState.sharedInstance.currentCoreOptions.append(ArcadiaCoreOption(key: String(cString: key), description: description, values: values))
                    
                }
                return true
                
            default:
                return false
            }
        }
    }

    public var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {
        return { frameBufferData, width, height, pitch in
            
            guard let frameBufferPtr = frameBufferData else {
                print("frame_buffer_data was null")
                return
            }
                     
            let height = Int(height)
            let width = Int(width)
            let pitch = pitch
            
            let bytesPerPixel: Int
            
            if ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat == .pixelFormatXRGB8888 {
                bytesPerPixel = 4 // XRGB8888 format
            } else if ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat == .pixelFormatRGB565 {
                bytesPerPixel = 2 // RGB565 format
            } else {
                print("Unsupported pixel format")
                return
            }

            let lengthOfFrameBuffer = height * pitch

            var pixelArray = [UInt8](repeating: 0, count: width * height * 4) // 4 bytes per pixel for output buffer
            let endianness = CFByteOrderGetCurrent()
            
            for y in 0..<height {
                let rowOffset = y * pitch
                for x in 0..<width {
                    let pixelOffset = rowOffset + x * bytesPerPixel
                    let rgbaOffset = y * width * 4 + x * 4

                    if ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat == .pixelFormatXRGB8888 {
                        
                        let blue = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt8.self)
                        let green = frameBufferPtr.load(fromByteOffset: pixelOffset + 1, as: UInt8.self)
                        let red = frameBufferPtr.load(fromByteOffset: pixelOffset + 2, as: UInt8.self)
                        let alpha = frameBufferPtr.load(fromByteOffset: pixelOffset + 3, as: UInt8.self)

                        if endianness == CFByteOrderLittleEndian.rawValue {
                             pixelArray[rgbaOffset] = blue
                             pixelArray[rgbaOffset + 1] = green
                             pixelArray[rgbaOffset + 2] = red
                             pixelArray[rgbaOffset + 3] = alpha
                        } else if endianness == CFByteOrderBigEndian.rawValue {
                            pixelArray[rgbaOffset] = red
                            pixelArray[rgbaOffset + 1] = green
                            pixelArray[rgbaOffset + 2] = blue
                            pixelArray[rgbaOffset + 3] = alpha
                        } else {
                            print( "unknown endianness")
                            return
                        }
                        

                    } else if ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat == .pixelFormatRGB565 {
                        let pixelData = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt16.self)
                        
                        let red = UInt8(((pixelData >> 11) & 0x1F) * 255 / 31)
                        let green = UInt8(((pixelData >> 5) & 0x3F) * 255 / 63)
                        let blue = UInt8((pixelData & 0x1F) * 255 / 31)
                        let alpha: UInt8 = 255

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
        if stateSize == 0 {
            return
        }
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
    
    public func saveMemoryData(memoryId: UInt32, saveFileURL: URL) {
        let saveSize = retroGetMemorySize(memoryDataId: memoryId)
        
        var saveBuffer = [UInt8](repeating: 0, count: saveSize)
        
        guard let memoryPosition = retroGetMemoryData(memoryDataId: memoryId) else {
            print("Failed to retrieve memory data.")
            return
        }
        
        saveBuffer.withUnsafeMutableBytes { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else { return }
            baseAddress.copyMemory(from: memoryPosition, byteCount: Int(saveSize))
        }
        
        do {
            try Data(saveBuffer).write(to: saveFileURL)
            print("Memory data saved successfully.")
        } catch {
            print("Error saving memory data: \(error)")
        }
        
    }
    public func loadMemoryData(memoryId: UInt32) {
        //TODO: load save file, and copy data into memory position???
    }
    
}

extension ArcadiaCoreProtocol {
    
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

