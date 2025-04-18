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
    case GET_PIXEL_FORMAT = 10
    case SET_INPUT_DESCRIPTORS = 11
    case SET_KEYBOARD_CALLBACK = 12
    case SET_DISK_CONTROL_INTERFACE = 13
    case SET_HW_RENDER = 14
    case GET_VARIABLE = 15
    case SET_VARIABLES = 16
    case GET_VARIABLE_UPDATE = 17
    case SET_SUPPORT_NO_GAME = 18
    case GET_LIBRETRO_PATH = 19
    case SET_FRAME_TIME_CALLBACK = 21
    case SET_AUDIO_CALLBACK = 22
    case GET_RUMBLE_INTERFACE = 23
    case GET_INPUT_DEVICE_CAPABILITIES = 24
    case GET_SENSOR_INTERFACE = 25
    case GET_CAMERA_INTERFACE = 26
    case GET_LOG_INTERFACE = 27
    case GET_PERF_INTERFACE = 28
    case GET_LOCATION_INTERFACE = 29
    case GET_CORE_ASSETS_DIRECTORY = 30
    case GET_SAVE_DIRECTORY = 31
    case SET_SYSTEM_AV_INFO = 32
    case SET_PROC_ADDRESS_CALLBACK = 33
    case SET_SUBSYSTEM_INFO = 34
    case SET_CONTROLLER_INFO = 35
    case SET_MEMORY_MAPS = 36
    case SET_GEOMETRY = 37
    case GET_USERNAME = 38
    case GET_LANGUAGE = 39
    case GET_CURRENT_SOFTWARE_FRAMEBUFFER = 40
    case GET_HW_RENDER_INTERFACE = 41
    case SET_SUPPORT_ACHIEVEMENTS = 42
    case SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE = 43
    case SET_SERIALIZATION_QUIRKS = 44
    case GET_VFS_INTERFACE = 45
    case GET_LED_INTERFACE = 46
    case GET_AUDIO_VIDEO_ENABLE = 47
    case GET_MIDI_INTERFACE = 48
    case GET_FASTFORWARDING = 49
    case GET_TARGET_REFRESH_RATE = 50
    case GET_INPUT_BITMASKS = 51
    case GET_CORE_OPTIONS_VERSION = 52
    case SET_CORE_OPTIONS = 53
    case SET_CORE_OPTIONS_INTL = 54
    case SET_CORE_OPTIONS_DISPLAY = 55
    case GET_PREFERRED_HW_RENDER = 56
    case GET_DISK_CONTROL_INTERFACE_VERSION = 57
    case SET_DISK_CONTROL_EXT_INTERFACE = 58
    case GET_MESSAGE_INTERFACE_VERSION = 59
    case SET_MESSAGE_EXT = 60
    case GET_INPUT_MAX_USERS = 61
    case SET_AUDIO_BUFFER_STATUS_CALLBACK = 62
    case SET_MINIMUM_AUDIO_LATENCY = 63
    case SET_FASTFORWARDING_OVERRIDE = 64
    case SET_CONTENT_INFO_OVERRIDE = 65
    case GET_GAME_INFO_EXT = 66
    case SET_CORE_OPTIONS_V2 = 67
    case SET_CORE_OPTIONS_V2_INTL = 68
    case SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK = 69
    case SET_VARIABLE = 70
    case GET_THROTTLE_STATE = 71
    case GET_SAVESTATE_CONTEXT = 72
    case GET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_SUPPORT = 73
    case GET_JIT_CAPABLE = 74
    case GET_MICROPHONE_INTERFACE = 75
    case SET_NETPACKET_INTERFACE = 76
    case GET_DEVICE_POWER = 77

}
