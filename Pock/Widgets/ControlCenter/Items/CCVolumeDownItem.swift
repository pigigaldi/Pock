//
//  ControlCenterVolumeDownItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class CCVolumeDownItem: ControlCenterItem {
    
    override var enabled: Bool{ return Defaults[.shouldShowVolumeItem] && Defaults[.shouldShowVolumeDownItem] }
    
    private let key: KeySender = KeySender(keyCode: NX_KEYTYPE_SOUND_DOWN, isAux: true)
    
    override var title: String  { return "volume-down" }
    
    override var icon:  NSImage { return NSImage(named: NSImage.touchBarVolumeDownTemplateName)! }
    
    override func action() -> Any? {
        key.send()
        return NSSound.systemVolume()
    }
    
    override func longPressAction() {
        parentWidget?.showSlideableController(for: self, currentValue: NSSound.systemVolume())
    }
    
    override func didSlide(at value: Double) {
        NSSound.setSystemVolume(Float(value))
        // DK_OSDUIHelper.showHUD(type: NSSound.isMuted() ? .mute : .volume, filled: CUnsignedInt(NSSound.systemVolume() * 16))
    }

}
