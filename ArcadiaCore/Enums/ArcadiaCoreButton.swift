//
//  iRetroCoreButton.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public enum ArcadiaCoreButton: UInt32, CaseIterable, Identifiable {
    
    public var id: Self {
        return self
    }
    
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
    case arcadiaButton = 16
    case joypadUpRight = 17
    case joypadUpLeft = 18
    case joypadDownRight = 19
    case joypadDownLeft = 20
    
    public var buttonsToPress: [UInt32] {
        switch self {
        case .joypadB:
            return [0]
        case .joypadY:
            return [1]
        case .joypadSelect:
            return [2]
        case .joypadStart:
            return [3]
        case .joypadUp:
            return [4]
        case .joypadDown:
            return [5]
        case .joypadLeft:
            return [6]
        case .joypadRight:
            return [7]
        case .joypadA:
            return [8]
        case .joypadX:
            return [9]
        case .joypadL:
            return [10]
        case .joypadR:
            return [11]
        case .joypadL2:
            return [12]
        case .joypadR2:
            return [13]
        case .joypadL3:
            return [14]
        case .joypadR3:
            return [15]
        case .arcadiaButton:
            return [16]
        case .joypadUpRight:
            return [4, 7]
        case .joypadUpLeft:
            return [4, 6]
        case .joypadDownRight:
            return [5, 7]
        case .joypadDownLeft:
            return [5, 6]
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .joypadB:
            return "b.circle.fill"
        case .joypadY:
            return "y.circle.fill"
        case .joypadSelect:
            return "minus.circle.fill"
        case .joypadStart:
            return "plus.circle.fill"
        case .joypadUp:
            return "arrowtriangle.up.circle.fill"
        case .joypadDown:
            return "arrowtriangle.down.circle.fill"
        case .joypadLeft:
            return "arrowtriangle.left.circle.fill"
        case .joypadRight:
            return "arrowtriangle.right.circle.fill"
        case .joypadA:
            return "a.circle.fill"
        case .joypadX:
            return "x.circle.fill"
        case .joypadL:
            return "l.rectangle.roundedbottom.fill"
        case .joypadR:
            return "r.rectangle.roundedbottom.fill"
        case .joypadL2:
            return "l2.rectangle.roundedtop.fill"
        case .joypadR2:
            return "r2.rectangle.roundedtop.fill"
        case .joypadL3:
            return "zl.rectangle.roundedtop.fill"
        case .joypadR3:
            return "zr.rectangle.roundedtop.fill"
        case .arcadiaButton:
            return "line.3.horizontal.circle.fill"
        case .joypadUpRight:
            return "arrow.up.right.circle.fill"
        case .joypadUpLeft:
            return "arrow.up.left.circle.fill"
        case .joypadDownRight:
            return "arrow.down.right.circle.fill"
        case .joypadDownLeft:
            return "arrow.down.left.circle.fill"
        }
    }
    
    public var mappingExplanation: String {
        switch self {
        case .joypadB:
            return "B button"
        case .joypadY:
            return "Y button"
        case .joypadSelect:
            return "Select button"
        case .joypadStart:
            return "plus.circle.fill"
        case .joypadUp:
            return "The up arrow in the direction pad"
        case .joypadDown:
            return "The down arrow in the direction pad"
        case .joypadLeft:
            return "The left arrow in the direction pad"
        case .joypadRight:
            return "The right arrow in the direction pad"
        case .joypadA:
            return "A button"
        case .joypadX:
            return "X button"
        case .joypadL:
            return "The top left shoulder button"
        case .joypadR:
            return "The top right shoulder button"
        case .joypadL2:
            return "The middle left shoulder button"
        case .joypadR2:
            return "The middle right shoulder button"
        case .joypadL3:
            return "The bottom left shoulder button"
        case .joypadR3:
            return "The bottom right shoulder button"
        case .arcadiaButton:
            return "Arcadia button: it lets you access useful in game functions such as saving states, changing player input, etc."
        case .joypadUpRight:
            return "Combo button that will press up and right simultaneously"
        case .joypadUpLeft:
            return "Combo button that will press up and left simultaneously"
        case .joypadDownRight:
            return "Combo button that will press down and right simultaneously"
        case .joypadDownLeft:
            return "Combo button that will press down and left simultaneously"
        }
    }
    
    public var buttonName: String {
        switch self {
        case .joypadB:
            return "B"
        case .joypadY:
            return "Y"
        case .joypadSelect:
            return "Select"
        case .joypadStart:
            return "Start"
        case .joypadUp:
            return "Arrow Up"
        case .joypadDown:
            return "Arrow Down"
        case .joypadLeft:
            return "Arrow Left"
        case .joypadRight:
            return "Arrow Right"
        case .joypadA:
            return "A"
        case .joypadX:
            return "X"
        case .joypadL:
            return "Left Shoulder"
        case .joypadR:
            return "Right Shoulder"
        case .joypadL2:
            return "Left Shoulder Two"
        case .joypadR2:
            return "Right Shoulder Two"
        case .joypadL3:
            return "Left Shoulder Three"
        case .joypadR3:
            return "Right Shoulder Three"
        case .arcadiaButton:
            return "Arcadia Button"
        case .joypadUpRight:
            return "Arrow Up Right"
        case .joypadUpLeft:
            return "Arrow Up Left"
        case .joypadDownRight:
            return "Arrow Down Right"
        case .joypadDownLeft:
            return "Arrow Down Left"
        }
    }
    
}
