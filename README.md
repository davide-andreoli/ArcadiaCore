# ArcadiaCore

This repository contains code for the ArcadiaCore framework, which is used to control emulation in the Arcadia App and to provide a protocol for all cores.

## Classes

The main class of the framework is ArcadiaCoreEmulationState, which acts as the central service for Arcadia, holding all properties useful for emulation (current game, current core, renderer, etc.).
This class controls the game loop and the save ram monitoring loop.

There are two more classes:

- ArcadiaCoreMetalRenderer: the class responsible for rendering frames with Metal
- ArcadiaCoreAudioPlayer: the class responsible for playing audio coming from the core

The emulation state is defined here because it is easier to update it within the ArcadiaCore protocol callbacks. 

## Protocol

The frameworks define ArcadiaCoreProtocol, which has to be adopted by every Arcadia core.
The protocol provides a default implementation for most Libretro API callbacks and functions, but expects the core to provide an implementation for low level functions such as retro_init, retro_load_game, etc.
This allows the protocol to be adopted by every core, ensuring that the actual core low level functions are called, while keeping the implementation common.
The protocol also provides some useful functions that can be used to interact with the core, such as saving data and so on.