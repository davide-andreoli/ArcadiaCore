//
//  ArcadiaCoreAudioPlayer.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 05/06/24.
//

import Foundation
import AVFoundation

public class ArcadiaCoreAudioPlayer {
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var audioFormat: AVAudioFormat
    public var sampleRate: Double = 44100

    private let bufferUpdateQueue = DispatchQueue(label: "com.Arcadia.bufferUpdateQueue", qos: .userInteractive)

    init() {
        
        //TODO: Allow the user to change the Audio Session based on settings options
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        #endif
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        let channels: AVAudioChannelCount = 2 // Two channels for stereo

        // Use Float32 format with non-interleaved data
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels) else {
            fatalError("Failed to create audio format")
        }
        audioFormat = format

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }

    func start() {
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func changeSampleRate(to newSampleRate: Double) {
        bufferUpdateQueue.sync {
            self.audioEngine.stop()
            self.audioEngine.reset()
            self.sampleRate = newSampleRate
            self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: newSampleRate, channels: self.audioFormat.channelCount)!
            
            self.audioEngine.detach(self.playerNode)
            self.playerNode = AVAudioPlayerNode()
            self.audioEngine.attach(self.playerNode)
            self.audioEngine.connect(self.playerNode, to: self.audioEngine.mainMixerNode, format: self.audioFormat)
        }
        
    }

    func updateBuffer(with audioData: [Float32]) {
        bufferUpdateQueue.async { [weak self] in
            guard let self = self else { return }
            
            let frameCount = AVAudioFrameCount(audioData.count / Int(self.audioFormat.channelCount))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat, frameCapacity: frameCount) else {
                print("Failed to create PCM buffer with frame capacity \(frameCount)")
                return
            }
            buffer.frameLength = frameCount

            // Get pointers to each channel's data buffer
            guard let channelData = buffer.floatChannelData else {
                print("Failed to get float channel data")
                return
            }

            // Directly copy the audio data into the channel buffers
            for channel in 0..<Int(self.audioFormat.channelCount) {
                let stride = Int(self.audioFormat.channelCount)
                for frame in 0..<Int(frameCount) {
                    channelData[channel][frame] = audioData[frame * stride + channel]
                }
            }
            
            self.playerNode.scheduleBuffer(buffer, completionHandler: nil) //Works but audio is late
            
            //self.playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil) // Works but audio is choppy
        }
    }

}
