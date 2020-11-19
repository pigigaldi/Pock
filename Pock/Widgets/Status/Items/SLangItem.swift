//
//  SWifiItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 23/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults
import Carbon

class SLangItem: StatusItem, ClickListener {
    
    /// UI
    private let iconView: NSClickableImageView = NSClickableImageView(frame: NSRect(x: 0, y: 0, width: 26, height: 26), id: -111)
    
    var tisInputSource: TISInputSource? = nil
    
    init() {
        iconView.clickDelegate = self
    }
    
    deinit {
        didUnload()
    }
    
    var enabled: Bool{ return Defaults[.shouldShowLangItem] }
    
    var title: String  { return "lang" }
    
    var view: NSView { return iconView }
    
    func action() {
        if !isProd { print("[Pock]: Lang Status icon tapped!") }
    }
    
    
    func didLoad() {
        iconView.imageAlignment = NSImageAlignment.alignCenter
        self.reload()
        // register input source listener
        DistributedNotificationCenter.default().addObserver(self,
        selector: #selector(selectedKeyboardInputSourceChanged),
        name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
        object: nil,
        suspensionBehavior: .deliverImmediately)
    }
    
    func didUnload() {
        DistributedNotificationCenter.default().removeObserver(self, name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil)
    }
    
    
    func reload() {
        // check if there is need to change the input source icon
        let tisInputSourceLocal = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        if (tisInputSource?.name == tisInputSourceLocal.name) {
            return
        }
        tisInputSource = nil
        tisInputSource = tisInputSourceLocal
        var iconImage: NSImage? = nil
        // try getting high-res icon url
        if let imageURL = tisInputSource!.iconImageURL {
            for url in [imageURL.retinaImageURL, imageURL.tiffImageURL, imageURL] {
                if let image = NSImage(contentsOf: url) {
                    iconImage = image
                    break
                }
            }
        }

        // get the iconRef if no high-res icon url is available
        if iconImage == nil, let iconRef = tisInputSource!.iconRef {
            iconImage = NSImage(iconRef: iconRef)
        }
        let defaults = UserDefaults.standard
        var blackColorsRecorded = 0
        //check if blackColorsRecorded is already ran as to not waste resources
        let blackColorsRecordedForTis = defaults.object(forKey: tisInputSource!.id)
        if (blackColorsRecordedForTis != nil) {
            blackColorsRecorded = blackColorsRecordedForTis as! Int
        } else {
            if let icon = iconImage {
                if let tiff = icon.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
                    // rounded corner offset is around 0,15625
                    // remove it and divide the height & width by 4
                    let dividedHeight = round((CGFloat(tiffData.size.height)*0.84375)/4.0)
                    let dividedWidth = round((CGFloat(tiffData.size.width)*0.84375)/4.0)
                    var pointsX = 4
                    while (pointsX > 0) {
                        var pointsY = 4
                        while (pointsY > 0) {
                            pointsY-=1
                            // get the pixel color of each one of the 16 sectors of the image
                            let color = tiffData.colorAt(x: Int(dividedWidth)*(pointsX+1), y: Int(dividedHeight)*(pointsY+1))
                            if let letOKColor = color {
                                let ciColor:CIColor = CIColor(color: letOKColor)!
                                #if DEBUG
                                print("Color at point: x: \(Int(dividedWidth)*pointsX) y: \(Int(dividedHeight)*pointsY) color: \(ciColor) pointsX: \(pointsX) pointsY: \(pointsY)")
                                #endif
                                // convert to rgb
                                if (ciColor.red == 0 && ciColor.blue == 0 && ciColor.green == 0) {
                                    blackColorsRecorded+=1
                                }
                            }
                        }
                        pointsX-=1
                    }
                    defaults.set(blackColorsRecorded, forKey: tisInputSource!.id)
                }
            }
        }
        
        if (blackColorsRecorded > 10) {
            iconImage = iconImage?.tint(color: NSColor.init(calibratedRed: 0.85, green: 0.85, blue: 0.85, alpha: 1))
        }
        // resize in order to fit the touchbar without blurriness when too big
        self.iconView.image = iconImage?.resizeWhileMaintainingAspectRatioToSize(size: NSSize(width: 18, height: 18))
    }
    
    // click handlers
    func didTapHandler() {
        if !Defaults[.shouldMakeClickable] {
            return
        }
        let tises = TISInputSource.sources
        let tisInputSourceLocal = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        var neededId = 0
        for i in 0..<tises.count {
            if tises[i].id == tisInputSourceLocal.id {
                if (i+1 < tises.count) {
                    neededId = i+1
                }
                break
            }
        }
        TISSelectInputSource(tises[neededId])
    }
        
    func didLongPressHandler() {
    }
    
    func didSwipeLeftHandler() {
    }
    
    func didSwipeRightHandler() {
    }
    
}

extension SLangItem {
    // this may be called twice
    @objc func selectedKeyboardInputSourceChanged() {
        self.reload()
    }
}

//credit: https://github.com/utatti/kawa
private extension URL {
    // try getting retina image from URL
    var retinaImageURL: URL {
        var components = pathComponents
        let filename: String = components.removeLast()
        let ext: String = pathExtension
        let retinaFilename = filename.replacingOccurrences(of: "." + ext, with: "@2x." + ext)
        return NSURL.fileURL(withPathComponents: components + [retinaFilename])!
    }

    // try getting high quality tiff from URL
    var tiffImageURL: URL {
        return deletingPathExtension().appendingPathExtension("tiff")
    }
}

// extension which makes getting properties from TISInputSource easier
extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!).takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var name: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }

    var iconImageURL: URL? {
        return getProperty(kTISPropertyIconImageURL) as! URL?
    }

    var iconRef: IconRef? {
        return OpaquePointer(TISGetInputSourceProperty(self, kTISPropertyIconRef)) as IconRef?
    }
    
    static var sources: [TISInputSource] {
      let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
      let inputSourceList = inputSourceNSArray as! [TISInputSource]

      return inputSourceList
        .filter {
          $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable
      }
    }
}


// credit: https://gist.github.com/MaciejGad/11d8469b218817290ee77012edb46608
extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
}
