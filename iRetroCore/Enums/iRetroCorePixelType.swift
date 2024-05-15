//
//  iRetroCorePixelType.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public enum iRetroCorePixelType: UInt32 {
    case pixelFormat0RGB1555 = 0
    case pixelFormatXRGB8888 = 1
    case pixelFormatRGB565 = 2
    case pixelFormatUnknown = 4294967295
    
    public init(rawValue: UInt32) {
        switch rawValue {
        case 0:
            self = .pixelFormat0RGB1555
        case 1:
            self = .pixelFormatXRGB8888
        case 2:
            self = .pixelFormatRGB565
        default:
            self = .pixelFormatUnknown
        }
    }
}
