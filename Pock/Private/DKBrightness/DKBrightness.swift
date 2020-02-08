//
//  DKBrightness.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class DKBrightness {
    
    class func increaseBrightness(by amount: Float) {
        let newValue = DKBrightness.getBrightnessLevel() + amount
        DKBrightness.setBrightnessLevel(level: newValue > 1.0 ? 1.0 : newValue)
    }
    
    class func decreaseBrightness(by amount: Float) {
        let newValue = DKBrightness.getBrightnessLevel() - amount
        DKBrightness.setBrightnessLevel(level: newValue < 0.0 ? 0.0 : newValue)
    }
    
    class func setBrightnessLevel(level: Float) {
        if #available(OSX 10.13, *) {
            CoreDisplay_Display_SetUserBrightness(0, Double(level))
        } else {
            var iterator: io_iterator_t = 0
            if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess {
                var service: io_object_t = 1
                while service != 0 {
                    service = IOIteratorNext(iterator)
                    IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
                    IOObjectRelease(service)
                }
            }
        }
    }
    
    class func getBrightnessLevel() -> Float {
        var brightness: Float = 0.0
        if #available(OSX 10.13, *) {
                brightness = Float32(CoreDisplay_Display_GetUserBrightness(0))
        } else {
            var iterator: io_iterator_t = 0
            if IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator) == kIOReturnSuccess {
                var service: io_object_t = 1
                while service != 0 {
                    service = IOIteratorNext(iterator)
                    IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
                    IOObjectRelease(service)
                }
            }
        }
        return brightness
    }
    
}
