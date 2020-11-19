//
// Battery.swift
// Apple Juice
// https://github.com/raphaelhanneken/apple-juice
//

import Foundation
import IOKit.ps

///  Notification name for the power source changed callback.
let powerSourceChangedNotification = "com.raphaelhanneken.apple-juice.powersourcechanged"

///  Posts a notification every time the power source changes.
private let powerSourceCallback: IOPowerSourceCallbackType = { _ in
    NotificationCenter.default.post(name: Notification.Name(rawValue: powerSourceChangedNotification),
                                    object: nil)
}

///  Accesses the battery's IO service.
final class BatteryService {

    /// Closed state value for the service connection object.
    private static let connectionClosed: UInt32 = 0

    /// An IOService object that matches battery's IO service dictionary.
    private var service: io_object_t = BatteryService.connectionClosed

    ///  The current status of the battery, e.g. charging.
    var state: BatteryState? {
        guard
            let plugged    = isPlugged,
            let charged    = isCharged,
            let percentage = percentage else {
                return nil
        }
        if charged && plugged {
            return .chargedAndPlugged
        }
        if plugged {
            return .charging(percentage: percentage)
        }

        return .discharging(percentage: percentage)
    }

    ///  The remaining time until the battery is empty or fully charged
    ///  in a human readable format, e.g. hh:mm.
    var timeRemainingFormatted: String {
        // Unwrap required information.
        guard let charged = isCharged, let plugged = isPlugged else {
            return NSLocalizedString("-1:-1", comment: "")
        }
        // Check if the battery is charged and plugged into an unlimited power supply.
        if charged && plugged {
            return NSLocalizedString("Full", comment: "")
        }
        // The battery is (dis)charging, display the remaining time.
        if let time = timeRemaining {
            return String(format: "%d:%02d", arguments: [time / 60, time % 60])
        }

        return NSLocalizedString("Wait", comment: "")
    }

    ///  The remaining time in _minutes_ until the battery is empty or fully charged.
    var timeRemaining: Int? {
        // Get the estimated time remaining.
        let time = IOPSGetTimeRemainingEstimate()

        switch time {
        case kIOPSTimeRemainingUnknown:
            return nil
        case kIOPSTimeRemainingUnlimited:
            // The battery is connected to a power outlet, get the remaining time
            // until the battery is fully charged.
            if let prop = getRegistryProperty(forKey: .timeRemaining) as? Int, prop < 600 {
                return prop
            }
            return nil
        default:
            // The estimated time in minutes
            return Int(time / 60)
        }
    }

    ///  The current percentage, based on the current charge and the maximum capacity.
    var percentage: Int? {
        return getPowerSourceProperty(forKey: .percentage) as? Int
    }

    /// The current percentage, formatted according to the selected client locale, e.g.
    /// en_US: 42% fr_FR: 42 %
    var percentageFormatted: String {
        guard let percentage = self.percentage else {
            return NSLocalizedString("Calculating", comment: "")
        }

        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        percentageFormatter.generatesDecimalNumbers = false
        percentageFormatter.localizesFormat = true
        percentageFormatter.multiplier = 1.0
        percentageFormatter.minimumFractionDigits = 0
        percentageFormatter.maximumFractionDigits = 0

        return percentageFormatter.string(from: percentage as NSNumber) ?? "\(percentage) %"
    }

    ///  The current charge in mAh.
    var charge: Int? {
        return getRegistryProperty(forKey: .currentCharge) as? Int
    }

    ///  The maximum capacity in mAh.
    var capacity: Int? {
        return getRegistryProperty(forKey: .maxCapacity) as? Int
    }

    ///  The source from which the Mac currently draws its power.
    var powerSource: String {
        guard let plugged = isPlugged else {
            return NSLocalizedString("Unknown", comment: "")
        }
        // Check whether the MacBook currently is plugged into a power adapter.
        if plugged {
            return NSLocalizedString("Power Adapter", comment: "")
        }

        return NSLocalizedString("Battery", comment: "")
    }

    ///  Checks whether the battery is charging and connected to a power outlet.
    var isCharging: Bool? {
        return getRegistryProperty(forKey: .isCharging) as? Bool
    }

    ///  Checks whether the battery is fully charged.
    var isCharged: Bool? {
        return getRegistryProperty(forKey: .fullyCharged) as? Bool
    }

    ///  Checks whether the battery is plugged into an unlimited power supply.
    var isPlugged: Bool? {
        return getRegistryProperty(forKey: .isPlugged) as? Bool
    }

    ///  Calculates the current power usage in Watts.
    var powerUsage: Double? {
        guard
            let voltage  = getRegistryProperty(forKey: .voltage) as? Double,
            let amperage = getRegistryProperty(forKey: .amperage) as? Double else {
            return nil
        }
        return round((voltage * amperage) / 1_000_000)
    }

    ///  Current flowing into or out of the battery.
    var amperage: Int? {
        guard
            let amperage = getRegistryProperty(forKey: .amperage) as? Int else {
                return nil
        }
        return amperage
    }

    /// The number of charging cycles.
    var cycleCount: Int? {
        return getRegistryProperty(forKey: .cycleCount) as? Int
    }

    /// The battery's current temperature.
    var temperature: Double? {
        guard let temp = getRegistryProperty(forKey: .temperature) as? Double else {
            return nil
        }
        return (temp / 100)
    }

    /// The batteries' health status
    var health: String? {
        return getPowerSourceProperty(forKey: .health) as? String
    }

    ///  Initializes a new Battery object.
    init() throws {
        try openServiceConnection()
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           IOPSNotificationCreateRunLoopSource(powerSourceCallback, nil).takeRetainedValue(),
                           CFRunLoopMode.defaultMode)
    }

    ///  Opens a connection to the battery's IOService object.
    ///
    ///  - throws: A BatteryError if something went wrong.
    private func openServiceConnection() throws {
        if service != BatteryService.connectionClosed && !closeServiceConnection() {
            // For some reason we have an open IO Service connection which we cannot close.
            throw BatteryError.connectionAlreadyOpen("Closing the IOService connection failed.")
        }
        service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                              IOServiceNameMatching(RegistryKey.service.rawValue))

        if service == BatteryService.connectionClosed {
            throw BatteryError
                .serviceNotFound("Opening the provided IOService (\(RegistryKey.service.rawValue)) failed.")
        }
    }

    ///  Closes the connection the the battery's IOService object.
    ///
    ///  - returns: True, when the IOService connection was successfully closed.
    public func closeServiceConnection() -> Bool {
        if kIOReturnSuccess == IOObjectRelease(service) {
            service = BatteryService.connectionClosed
        }

        return (service == BatteryService.connectionClosed)
    }

    ///  Get the registry entry's property for the supplied SmartBatteryKey.
    ///
    ///  - parameter key: A SmartBatteryKey to get the corresponding registry entry's property.
    ///  - returns:       The registry entry for the provided SmartBatteryKey.
    private func getRegistryProperty(forKey key: RegistryKey) -> AnyObject? {
        return IORegistryEntryCreateCFProperty(service, key.rawValue as CFString?, nil, 0)
            .takeRetainedValue()
    }

    private func getPowerSourceProperty(forKey key: RegistryKey) -> Any? {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as? [CFDictionary]

        guard let powerSources = psList else {
            return nil
        }
        let powerSource = powerSources[0] as NSDictionary

        return powerSource[key.rawValue]
    }
}
