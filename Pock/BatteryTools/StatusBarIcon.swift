//
// StatusBarIcon.swift
// Apple Juice
// https://github.com/raphaelhanneken/apple-juice
//

import Cocoa

///  Image names for the images used by the menu bar item icon.
private enum BatteryImage: NSImage.Name {
    case left = "BatteryFillCapLeft"
    case right = "BatteryFillCapRight"
    case middle = "BatteryFill"
    case outline = "BatteryOutline"
    case charging = "Charging"
    case chargingSymbol = "ChargingSymbol"
    case chargedAndPlugged = "ChargedAndPlugged"
    case deadCropped = "DeadCropped"
    case none = "None"
    case lowBattery = "LowBattery"
}

internal struct StatusBarIcon {

    ///  The little margins between the battery outline and the capcity bar.
    private let capacityOffsetX: CGFloat = 2.0
    private let capacityOffsetY: CGFloat = 2.0

    ///  Cache the last drawn battery icon.
    private var cache: BatteryImageCache?

    ///  Draws a battery icon for the given BatteryState.
    ///
    ///  - parameter status: The BatteryState for the status the battery is currently in, e.g. charging
    ///  - returns: The battery image for the provided battery status.
    mutating internal func drawBatteryImage(forStatus status: BatteryState) -> NSImage? {
        if let cache = self.cache, cache.batteryStatus == status {
            return cache.image
        }

        switch status {
        case .charging:
            cache = BatteryImageCache(forStatus: status,
                                      withImage: batteryImage(named: .charging))
        case .chargedAndPlugged:
            cache = BatteryImageCache(forStatus: status,
                                      withImage: batteryImage(named: .chargedAndPlugged))
        case let .discharging(percentage):
            cache = BatteryImageCache(forStatus: status,
                                      withImage: dischargingBatteryImage(forPercentage: Double(percentage)))
        }

        return cache?.image
    }

    ///  Draws a battery icon for the given BatteryError.
    ///
    ///  - parameter err: The BatteryError object for the corresponding error that happened.
    ///  - returns: A battery icon for the given BatteryError.
    internal func drawBatteryImage(forError error: BatteryError?) -> NSImage? {
        guard let error = error else { return nil }

        switch error {
        case .connectionAlreadyOpen:
            return batteryImage(named: .deadCropped)
        case .serviceNotFound:
            return batteryImage(named: .none)
        }
    }

    ///  Draws a battery icon based on the battery's current percentage.
    ///
    ///  - parameter percentage: The current percentage of the battery.
    ///  - returns: A battery icon for the supplied percentage.
    private func dischargingBatteryImage(forPercentage percentage: Double) -> NSImage? {
        guard let batteryOutline = batteryImage(named: .outline),
              let capacityCapLeft = batteryImage(named: .left),
              let capacityCapRight = batteryImage(named: .right),
              let capacityFill = batteryImage(named: .middle) else {
            return nil
        }

        // Delete the image name for the battery outline to keep it's representations out of the NSCachedImageRep
        batteryOutline.setName(nil)
        let drawingRect = NSRect(x: capacityOffsetX,
                                 y: capacityOffsetY,
                                 width: CGFloat(round(percentage / drawingPrecision)) * capacityFill.size.width,
                                 height: capacityFill.size.height)

        // NSImage#drawThreePartImage glitchets when the width of the capacity bar drops
        // below the combined width of startCap and endCap.
        if drawingRect.width < (2 * capacityFill.size.width) {
            return batteryImage(named: .lowBattery)
        }

        return batteryOutline.drawThreePartImage(withStartCap: capacityCapLeft,
                                                 fill: capacityFill,
                                                 endCap: capacityCapRight,
                                                 inFrame: drawingRect)
    }
    
    ///  Draws a battery icon based on the battery's current percentage.
    ///
    ///  - parameter percentage: The current percentage of the battery.
    ///  - returns: A battery icon for the supplied percentage.
    private func chargingBatteryImage(forPercentage percentage: Double) -> NSImage? {
        guard let batteryOutline = batteryImage(named: .outline),
              let capacityCapLeft = batteryImage(named: .left),
              let capacityCapRight = batteryImage(named: .right),
              let capacityFill = batteryImage(named: .middle) else {
            return nil
        }

        // Delete the image name for the battery outline to keep it's representations out of the NSCachedImageRep
        batteryOutline.setName(nil)
        batteryOutline.isTemplate = false
        let drawingRect = NSRect(x: capacityOffsetX,
                                 y: capacityOffsetY,
                                 width: CGFloat(round(percentage / drawingPrecision)) * capacityFill.size.width,
                                 height: capacityFill.size.height)

        // NSImage#drawThreePartImage glitchets when the width of the capacity bar drops
        // below the combined width of startCap and endCap.
        if drawingRect.width < (2 * capacityFill.size.width) {
            return batteryImage(named: .lowBattery)
        }
        
        batteryOutline.drawThreePartImage(withStartCap: capacityCapLeft,
                                                 fill: capacityFill,
                                                 endCap: capacityCapRight,
                                                 inFrame: drawingRect).tint(color: NSColor.white, noCopy: true)

        if let image = batteryImage(named: .chargingSymbol)?.tint(color: NSColor.black) {
            batteryOutline.lockFocus()
            image.draw(in: CGRect(x: (batteryOutline.size.width-image.size.width)/2, y: (batteryOutline.size.height-image.size.height)/2, width: image.size.width, height: image.size.height))
            batteryOutline.unlockFocus()
        }
        
        return batteryOutline
    }

    ///  Returns the image object associated with the specified name as template.
    ///
    ///  - parameter name: The name of an image in the app bundle.
    ///  - returns: An image object associated with the specified name as template.
    private func batteryImage(named name: BatteryImage) -> NSImage? {
        guard let img = NSImage(named: name.rawValue) else { return nil }
        img.isTemplate = true

        return img
    }

}
