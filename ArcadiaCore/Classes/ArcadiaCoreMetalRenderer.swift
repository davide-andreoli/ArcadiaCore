//
//  ArcadiaCoreMetalRenderer.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 06/06/24.
//

import MetalKit

public class ArcadiaCoreMetalRenderer: NSObject, MTKViewDelegate {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var texture: MTLTexture?

    override init() {
        super.init()
        setupMetal()
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Failed to create Metal device")
            return
        }
        commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library")
            return
        }
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }

    func updateTexture(with pixelData: [UInt8], width: Int, height: Int) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        if texture == nil || texture?.width != width || texture?.height != height {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.pixelFormat = .bgra8Unorm
            textureDescriptor.width = width
            textureDescriptor.height = height
            textureDescriptor.usage = .shaderRead

            texture = device.makeTexture(descriptor: textureDescriptor)
        }
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: 4 * width)
        //print("Texture updated with size \(width)x\(height)")
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes if necessary
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            print("Failed to get drawable or descriptor")
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)

        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setFragmentTexture(texture, index: 0)
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        //print("Drawing frame")
    }
}
