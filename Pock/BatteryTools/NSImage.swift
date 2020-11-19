//
// PreferenceKeys.swift
// Apple Juice
// https://github.com/raphaelhanneken/apple-juice
//

import Cocoa

extension NSImage {

    func drawThreePartImage(
        withStartCap startCap: NSImage,
        fill: NSImage,
        endCap: NSImage,
        inFrame frame: NSRect
    ) -> NSImage {
        lockFocus()
        NSDrawThreePartImage(frame, startCap, fill, endCap, false, .copy, 1, false)
        unlockFocus()

        return self
    }

}
