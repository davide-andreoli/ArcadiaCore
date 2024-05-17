//
//  ArcadiaCallbackType.swift
//  ArcadiaCore
//
//  Created by Davide Andreoli on 17/05/24.
//

import Foundation

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
    case SET_CONTROLLER_INFO = 35
    case GET_CORE_OPTIONS_VERSION = 52
    case GET_MESSAGE_INTERFACE_VERSION = 59
    case SET_FASTFORWARDING_OVERRIDE = 64
    case SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK = 69
    case SET_VARIABLE = 70

}
