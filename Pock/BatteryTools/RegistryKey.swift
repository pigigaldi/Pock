//
// SmartBatteryKeys.swift
// Apple Juice
// https://github.com/raphaelhanneken/apple-juice
//

/// Keys to lookup information from the IO Service dictionary 'ioreg -brc AppleSmartBattery'.
///
/// - isPlugged: Is the battery connected to an external power source
/// - isCharging: The battery's charging state
/// - currentCharge: An estimate about the current charge in mAh
/// - maxCapacity: The maximun charging capacity in mAh
/// - fullyCharged: Is the battery's max charging capacity reached
/// - cycleCount: The number of charging cycles
/// - temperature: The temperature in degrees celsius
/// - voltage: The current voltage
/// - amperage: The current amperage
/// - timeRemaining: An estimate about the remaining time until the battery is fully charged or depleted
/// - service: The service name
enum RegistryKey: String {
    case isPlugged     = "ExternalConnected"
    case isCharging    = "IsCharging"
    case currentCharge = "CurrentCapacity"
    case maxCapacity   = "MaxCapacity"
    case fullyCharged  = "FullyCharged"
    case cycleCount    = "CycleCount"
    case temperature   = "Temperature"
    case voltage       = "Voltage"
    case amperage      = "Amperage"
    case timeRemaining = "TimeRemaining"
    case service       = "AppleSmartBattery"
    case health        = "BatteryHealth"
    case percentage    = "Current Capacity"
}
