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

public extension Notification.Name {
    static let arcadiaVibrationNotification = Notification.Name("arcadiaVibrationNotification")
}

public struct ArcadiaVibrationNotification {
    public let port: UInt32
    public let effect: retro_rumble_effect
    public let strength: UInt16
}

public protocol ArcadiaCoreProtocol {
    
    associatedtype ArcadiaCoreType: ArcadiaCoreProtocol
        
    var paused: Bool {get set}
    var initialized: Bool {get set}
    var loadedGame: URL? {get set}
    var currentSaveRamSnapshot: [UInt32 : [UInt8]]? {get set}
    var defaultCoreOptions: [ArcadiaCoreOption] {get set}
    var audioVideoInfo: retro_system_av_info {get set}
    
    // Libretro Callbacks
    var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {get}
    var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {get}
    var libretroAudioSampleCallback: @convention(c) (Int16, Int16) -> Void {get}
    var libretroAudioSampleBatchCallback: @convention(c) (UnsafePointer<Int16>?, Int) -> Int {get}
    var libretroInputPollCallback: @convention(c) () -> Void {get}
    var libretroInputStateCallback: @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16 {get}
    
    // Libretro API Interfaces - To be implemented by the core
    func retroInit()
    func retroGetSystemAVInfo(info: UnsafeMutablePointer<retro_system_av_info>!)
    func retroDeinit()
    func retroRun()
    func retroReset()
    func retroLoadGame(gameInfo: retro_game_info) -> Bool
    func retroUnloadGame()
    func retroSerializeSize() -> Int
    func retroSerialize(data: UnsafeMutableRawPointer!, size: Int)
    func retroUnserialize(data: UnsafeRawPointer!, size: Int)
    func retroGetMemorySize(memoryDataId: UInt32) -> Int
    func retroGetMemoryData(memoryDataId: UInt32) -> UnsafeMutableRawPointer!
    func retroSetEnvironment(environmentCallback: retro_environment_t)
    func retroSetVideoRefresh(videoRefreshCallback: retro_video_refresh_t)
    func retroSetAudioSample(audioSampleCallback: retro_audio_sample_t)
    func retroSetAudioSampleBatch(audioSampleBatchCallback: retro_audio_sample_batch_t)
    func retroSetInputPoll(inputPollCallback: retro_input_poll_t)
    func retroSetInputState(inputStateCallback: retro_input_state_t)
    
    // Frontend/Complex interfaces
    func setInputOutputCallbacks()
    mutating func initializeCore()
    mutating func deinitializeCore()
    mutating func getSystemAVInfo()
    mutating func loadGame(gameURL: URL) -> Bool
    mutating func unloadGame()
    func saveState(saveFileURL: URL)
    func loadState(saveFileURL: URL)
    func saveMemoryData(memoryId: UInt32, saveFileURL: URL)
    mutating func loadBatterySave(from location: URL, memoryDataId: UInt32)
    mutating func takeInitialSaveRamSnapshot(memoryDataId: UInt32)
    mutating func checkForSaveRamModification(memoryDataId: UInt32) -> Bool
    mutating func pauseGame()
    mutating func resumeGame()
    
}


// Libretro Callbacks
extension ArcadiaCoreProtocol {
    
    public var libretroEnvironmentCallback: @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool {
        return {command, data in
            switch command {
            case 3:
                //GET_CAN_DUPE
                data?.storeBytes(of: true, as: Bool.self)
                return true
            case 8:
                //SET_PERFORMANCE_LEVEL
                if let data = data {
                    // Set performance level to 2
                    let performanceLevel: UInt32 = 2
                    data.storeBytes(of: performanceLevel, as: UInt32.self)
                    print("Performance level set to \(performanceLevel)")
                }
                return true
            case 9:
                // GET_SYSTEM_DIRECTORY
                let url = ArcadiaCoreEmulationState.sharedInstance.currentGameType!.getCoreDirectory
                
                let path = url.path
                
                guard let systemDirCString = strdup(path) else {
                    fatalError("Failed to duplicate filepath")
                }
                
                // Store the pointer to the C string in data
                data?.storeBytes(of: systemDirCString, as: UnsafePointer<CChar>.self)
                
                return true
            case 10:
                // GET_PIXEL_FORMAT
                ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat = ArcadiaCorePixelType(rawValue: data!.load(as: UInt32.self))
                return true
            case 11:
                //SET_INPUT_DESCRIPTORS
                // Assuming data contains an array of retro_input_descriptors structs
                // terminated by a { NULL, NULL } element
                var variables: [retro_input_descriptor] = []
                let pointer = data!.bindMemory(to: retro_input_descriptor.self, capacity: 1)
                var index = 0
                while pointer[index].description != nil {
                    variables.append(pointer[index])
                    index += 1
                }

                for variable in variables {
                    guard let description = variable.description else { continue }
                    let device = variable.device
                    let port = variable.port
                    let id = variable.id
                    print("Description: \(String(cString: description)), device: \(device), port: \(port), id: \(id)")


                    if ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port] == nil {
                        ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port] = [:]
                    }
                    
                    if ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device] == nil {
                        ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device] = [:]
                    }
                    
                    if ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device]?[0] == nil {
                        ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device]?[0] = [:]
                    }
                    if ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device]?[0]?[id] == nil {
                        ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device]?[0]?[id] = Int16(0)
                    }
                    
                }
                return true
            case 15:
                if ArcadiaCoreEmulationState.sharedInstance.coreOptionsToApply.isEmpty {
                    return false
                } else {
                    let coreOption = ArcadiaCoreEmulationState.sharedInstance.coreOptionsToApply.removeFirst()
                    data?.storeBytes(of: coreOption.getRetroVariable(), as: retro_variable.self)
                    ArcadiaCoreEmulationState.sharedInstance.appliedCoreOptions.append(coreOption)
                    return true
                }
            case 16:
                //SET_VARIABLES
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
            case 17:
                // GET_VARIABLE_UPDATE
                if ArcadiaCoreEmulationState.sharedInstance.coreOptionsToApply.isEmpty {
                    return false
                } else {
                    return true
                }
            case 23:
                // GET_RUMBLE_INTERFACE
                let rumbleCallback: @convention(c) (UInt32, retro_rumble_effect, UInt16) -> Bool =
                     { port, effect, strength in
                         print("Sending notification")
                         NotificationCenter.default.post(name: .arcadiaVibrationNotification, object: ArcadiaVibrationNotification(port: port, effect: effect, strength: strength))
                        return true
                    }
                
                let rumbleInterface = retro_rumble_interface(set_rumble_state: rumbleCallback)
                data?.storeBytes(of: rumbleInterface, as: retro_rumble_interface.self)
                return true
            case 27:
                #if DEBUG
                let libretroLogCallback: @convention(c) (retro_log_level, UnsafePointer<Int8>, UnsafeMutableRawPointer?) -> Void = {
                    level, message, argPointer in
                
                    let levelString: String
                    switch level {
                    case RETRO_LOG_DEBUG:
                        levelString = "DEBUG"
                    case RETRO_LOG_INFO:
                        levelString = "INFO"
                    case RETRO_LOG_WARN:
                        levelString = "WARN"
                    case RETRO_LOG_ERROR:
                        levelString = "ERROR"
                    case RETRO_LOG_DUMMY:
                        levelString = "DUMMY"
                    default:
                        levelString = "DEFAULT"
                    }
                        
                    let messageString = String(cString: message)
                    var formattedString = messageString
                    
                    
                    //TODO: Handle multiple Args by counting the placeholders inside the message
                    //TODO: Make this more solid on iOS, sometimes it does not work and sometimes it crashes for EXC_BAD_ACCESS
                    #if os(macOS)
                        #if arch(x86_64)
                            #if DEBUG
                    if let args = argPointer {
                        let argsPointer = args.bindMemory(to: CVarArg.self, capacity: 1)
                        withVaList([argsPointer]) { vaList in
                            formattedString = NSString(format: messageString, arguments: vaList) as String
                        }
                    }
                            #endif
                        #endif
                    #endif
                    print("[\(levelString)] \(messageString)")
                    
                }
                
                let pointer = unsafeBitCast(libretroLogCallback, to: retro_log_printf_t.self)
                let callback = retro_log_callback(log: pointer)
                data?.storeBytes(of: callback, as: retro_log_callback.self)
                return true
                #else
                return false
                #endif
            case 31:
                //GET_SAVE_DIRECTORY
                let url = ArcadiaCoreEmulationState.sharedInstance.currentGameType!.getSaveDirectory
                
                let path = url.path
                
                guard let systemDirCString = strdup(path) else {
                    fatalError("Failed to duplicate filepath")
                }
                
                // Store the pointer to the C string in data
                data?.storeBytes(of: systemDirCString, as: UnsafePointer<CChar>.self)
                return true
            case 35:
                //SET_CONTROLLER_INFO
                return false
            case 37:
                //SET_GEOMETRY
                let geometry = data!.load(as: retro_game_geometry.self)
                if ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_width != geometry.base_width {
                    ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_width = geometry.base_width
                }
                if ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_height != geometry.base_height {
                    ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_height = geometry.base_height
                }
                return true
            case 52:
                // GET_CORE_OPTIONS_VERSION
                // Not going to implement core options as of right now
                return false
            default:
                if let arcadiaCommand = ArcadiaCallbackType(rawValue: command) {
                    print("Not managed: \(command) - \(arcadiaCommand)")
                } else {
                    print("Unknown \(command)")
                }
                return false
            }
        }
    }
    
    
    public var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {
        return { frameBufferData, width, height, pitch in
            
            guard let pointer = libretro_video_refresh_callback(frameBufferData, width, height, Int32(pitch), retro_pixel_format(ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat.rawValue)) else {
                return
            }
            let length = Int(width * height * 4)
            let bufferPointer = UnsafeBufferPointer(start: pointer, count: length)
            ArcadiaCoreEmulationState.sharedInstance.mainBuffer = Array(bufferPointer)
            if ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_width != width {
                ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_width = width
            }
            if ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_height != height {
                ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo?.geometry.base_height = height
            }
            ArcadiaCoreEmulationState.sharedInstance.mainBuffer = Array(bufferPointer)
            ArcadiaCoreEmulationState.sharedInstance.metalRendered.updateTexture(with: Array(bufferPointer), width: Int(width), height: Int(height))
            free(pointer)
        }
    }
     /*
    public var libretroVideoRefreshCallback: @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void {
        return { frameBufferData, width, height, pitch in
            guard let frameBufferPtr = frameBufferData else {
                print("frame_buffer_data was null")
                return
            }
            
            let height = Int(height)
            let width = Int(width)
            let bytesPerPixel: Int
            let pixelFormat = ArcadiaCoreEmulationState.sharedInstance.mainBufferPixelFormat
            
            switch pixelFormat {
            case .pixelFormatXRGB8888:
                bytesPerPixel = 4 // XRGB8888 format
            case .pixelFormatRGB565:
                bytesPerPixel = 2 // RGB565 format
            default:
                print("Unsupported pixel format")
                return
            }
            
            let pixelArraySize = width * height * 4
            var pixelArray = [UInt8](repeating: 0, count: pixelArraySize)
            let endianness = CFByteOrderGetCurrent()
            
            for y in 0..<height {
                let rowOffset = y * pitch
                for x in 0..<width {
                    let pixelOffset = rowOffset + x * bytesPerPixel
                    let rgbaOffset = y * width * 4 + x * 4
                    
                    switch pixelFormat {
                    case .pixelFormatXRGB8888:
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
                            print("Unknown endianness")
                            return
                        }
                        
                    case .pixelFormatRGB565:
                        let pixelData = frameBufferPtr.load(fromByteOffset: pixelOffset, as: UInt16.self)
                        let red = UInt8(((pixelData >> 11) & 0x1F) * 255 / 31)
                        let green = UInt8(((pixelData >> 5) & 0x3F) * 255 / 63)
                        let blue = UInt8((pixelData & 0x1F) * 255 / 31)
                        let alpha: UInt8 = 255
                        
                        pixelArray[rgbaOffset] = blue
                        pixelArray[rgbaOffset + 1] = green
                        pixelArray[rgbaOffset + 2] = red
                        pixelArray[rgbaOffset + 3] = alpha
                    default:
                        return
                    }
                }
            }
            ArcadiaCoreEmulationState.sharedInstance.mainBuffer = pixelArray
        }
    }
      */

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
            let pointer = UnsafeMutablePointer<Float>.allocate(capacity: frames * 2)
            convert_s16_to_float(pointer, data, frames * 2, 1)
            
            let audioBufferFloat = UnsafeBufferPointer(start: pointer, count: frames * 2)
            let audioSliceFloat = Array(audioBufferFloat)
            ArcadiaCoreEmulationState.sharedInstance.audioPlayer.updateBuffer(with: audioSliceFloat)
            //ArcadiaCoreEmulationState.sharedInstance.currentAudioFrameFloat = audioSliceFloat
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
            if ArcadiaCoreEmulationState.sharedInstance.checkForPress(port: port, device: device, index: index, button: id) {
                return Int16(1)
            }
            return Int16(0)
            /*
            //print("Polling port: \(port), dev: \(device), index: \(index), id: \(id)")
            if ArcadiaCoreEmulationState.sharedInstance.pressedButtons[port]?[device]?[index]?[id] == 1 {
                //print("Got port: \(port), dev: \(device), index: \(index), id: \(id)")
                
                return Int16(1)
            }
            return Int16(0)
            */
            /*
            if ArcadiaCoreEmulationState.sharedInstance.checkForPress(port: port, device: device, index: index, button: id) {
                return Int16(1)
            }
            return Int16(0)
            */
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
        var avInfo = retro_system_av_info(geometry: retro_game_geometry(base_width: 0, base_height: 0, max_width: 0, max_height: 0, aspect_ratio: 0.0), timing: retro_system_timing(fps: 0.0, sample_rate: 0.0))
        retroGetSystemAVInfo(info: &avInfo)
        ArcadiaCoreEmulationState.sharedInstance.audioVideoInfo = avInfo
        self.audioVideoInfo = avInfo
    }
    
    mutating public func initializeCore() {
        if initialized == false {
            retroSetEnvironment(environmentCallback: libretroEnvironmentCallback)
            retroInit()
            getSystemAVInfo()
            print(self.audioVideoInfo)
            initialized = true
        }
    }
    
    mutating public func deinitializeCore() {
        if initialized == true {
            retroDeinit()
            initialized = false
        }
    }
    
    mutating public func loadGame(gameURL: URL) -> Bool {
        let filepath = gameURL.path

        guard let romNameCstr = strdup(filepath) else {
            fatalError("Failed to duplicate filepath")
        }
        defer {
            free(romNameCstr)
        }
        let romNameCptr = UnsafePointer<CChar>(romNameCstr)

        guard let romFile = try? Data(contentsOf: gameURL) else {
            fatalError("Failed to read file")
        }
        let data = romFile.withUnsafeBytes { $0.baseAddress }

        let rom_info = retro_game_info(path: romNameCptr, data: data, size: romFile.count, meta: nil)
        let result = retroLoadGame(gameInfo: rom_info)
        
        if result {
            self.loadedGame = gameURL
            ArcadiaCoreEmulationState.sharedInstance.currentGameURL = gameURL
        } else {
            self.loadedGame = nil
            ArcadiaCoreEmulationState.sharedInstance.currentGameURL = nil
        }
        
        return result
    }
    
    mutating public func unloadGame() {
        ArcadiaCoreEmulationState.sharedInstance.currentGameURL = nil
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
            let saveFileContent = try Data(contentsOf: saveFileURL)
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
        print("Saving memory data")
        let saveSize = retroGetMemorySize(memoryDataId: memoryId)
        if saveSize == 0 {
            return
        }
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
            print("Memory data saved successfully in \(saveFileURL).")
        } catch {
            print("Error saving memory data: \(error)")
        }
        
    }
    
    mutating public func takeInitialSaveRamSnapshot(memoryDataId: UInt32) {
        guard let saveRamPointer = retroGetMemoryData(memoryDataId: memoryDataId) else { return }
        let saveRamSize = retroGetMemorySize(memoryDataId: memoryDataId)
        
        if saveRamSize > 0 {
            let initialSaveRam = saveRamPointer.assumingMemoryBound(to: UInt8.self)
            self.currentSaveRamSnapshot?[memoryDataId] = Array(UnsafeBufferPointer(start: initialSaveRam, count: saveRamSize))
        }
    }
    
    mutating public func checkForSaveRamModification(memoryDataId: UInt32) -> Bool {
        guard let currentSaveRamPointer = retroGetMemoryData(memoryDataId: memoryDataId)?.assumingMemoryBound(to: UInt8.self),
              let saveRamSnapshot = self.currentSaveRamSnapshot?[memoryDataId] else { return false }
        let saveRamSize = retroGetMemorySize(memoryDataId: memoryDataId)
        let currentSaveRam = Array(UnsafeBufferPointer(start: currentSaveRamPointer, count: saveRamSize))
        
        if currentSaveRam != saveRamSnapshot {
            // Update the snapshot with the current state
            self.currentSaveRamSnapshot?[memoryDataId] = currentSaveRam
            return true // Save RAM has been modified
        }
        return false // No changes detected
    }
    
    mutating public func loadBatterySave(from location: URL, memoryDataId: UInt32) {
        print("Loading battery save")
        guard let saveRamPointer = retroGetMemoryData(memoryDataId: memoryDataId)?.assumingMemoryBound(to: UInt8.self) else {
            print("Failed to get save RAM pointer")
            return
        }
        let saveRamSize = retroGetMemorySize(memoryDataId: memoryDataId)
        
        do {
            let data = try Data(contentsOf: location)
            guard data.count == saveRamSize else {
                print("Save file size does not match expected size")
                return
            }
            data.copyBytes(to: saveRamPointer, count: saveRamSize)
            self.currentSaveRamSnapshot?[memoryDataId] = [UInt8](data)
            
        } catch {
            print("Failed to load battery save: \(error)")
        }
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



