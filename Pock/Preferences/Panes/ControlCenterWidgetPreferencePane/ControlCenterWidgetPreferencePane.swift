//
//  ControlCenterWidgetPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 06/07/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class ControlCenterWidgetPreferencePane: NSViewController, PreferencePane {

    /// UI
    @IBOutlet weak var showSleepItem:             NSButton!
    @IBOutlet weak var showLockItem:              NSButton!
    @IBOutlet weak var showScreensaverItem:       NSButton!
    @IBOutlet weak var showBrightnessItem:        NSButton!
    @IBOutlet weak var showVolumeItem:            NSButton!
    @IBOutlet weak var showBrightnessDownItem:    NSButton!
    @IBOutlet weak var showBrightnessUpItem:      NSButton!
    @IBOutlet weak var showBrightnessToggleItem:  NSButton!
    @IBOutlet weak var showVolumeDownItem:        NSButton!
    @IBOutlet weak var showVolumeUpItem:          NSButton!
    @IBOutlet weak var showVolumeMuteItem:        NSButton!
    @IBOutlet weak var showVolumeToggleItem:      NSButton!
    
    /// Preferenceable
    var preferencePaneIdentifier: Preferences.PaneIdentifier = Preferences.PaneIdentifier.controler_center_widget
    let preferencePaneTitle:      String     = "Control Center Widget".localized
    var toolbarItemIcon:          NSImage    = NSImage(named: "ControlCenterWidget")!
    
    override var nibName: NSNib.Name? {
        return "ControlCenterWidgetPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.superview?.wantsLayer = true
        self.view.wantsLayer = true
        self.loadCheckboxState()
    }
    
    private func loadCheckboxState() {
        self.showSleepItem.state            = Defaults[.shouldShowSleepItem]          ? .on : .off
        self.showLockItem.state             = Defaults[.shouldShowLockItem]           ? .on : .off
        self.showScreensaverItem.state      = Defaults[.shouldShowScreensaverItem]    ? .on : .off
        self.showBrightnessItem.state       = Defaults[.shouldShowBrightnessItem]     ? .on : .off
        self.showVolumeItem.state           = Defaults[.shouldShowVolumeItem]         ? .on : .off
        self.showBrightnessDownItem.state   = Defaults[.shouldShowBrightnessDownItem] ? .on : .off
        self.showBrightnessUpItem.state     = Defaults[.shouldShowBrightnessUpItem]   ? .on : .off
        self.showBrightnessToggleItem.state = Defaults[.shouldShowBrightnessToggleItem] ? .on : .off
        self.showVolumeDownItem.state       = Defaults[.shouldShowVolumeDownItem]     ? .on : .off
        self.showVolumeUpItem.state         = Defaults[.shouldShowVolumeUpItem]       ? .on : .off
        self.showVolumeMuteItem.state       = Defaults[.shouldShowVolumeMuteItem]     ? .on : .off
        self.showVolumeToggleItem.state     = Defaults[.shouldShowVolumeToggleItem]     ? .on : .off
      
        self.showBrightnessDownItem.isEnabled   = Defaults[.shouldShowBrightnessItem]
        self.showBrightnessUpItem.isEnabled     = Defaults[.shouldShowBrightnessItem]
        self.showBrightnessToggleItem.isEnabled = Defaults[.shouldShowBrightnessItem]
        self.showVolumeDownItem.isEnabled       = Defaults[.shouldShowVolumeItem]
        self.showVolumeUpItem.isEnabled         = Defaults[.shouldShowVolumeItem]
        self.showVolumeMuteItem.isEnabled       = Defaults[.shouldShowVolumeItem]
        self.showVolumeToggleItem.isEnabled     = Defaults[.shouldShowVolumeItem]
    }
    
    @IBAction func didChangeCheckboxValue(_ checkbox: NSButton) {
        var key: Defaults.Key<Bool>
        switch checkbox.tag {
        case 1:
            key = .shouldShowSleepItem
        case 2:
            key = .shouldShowLockItem
        case 3:
            key = .shouldShowScreensaverItem
        case 4:
            key = .shouldShowDoNotDisturbItem
        case 5:
            key = .shouldShowBrightnessItem
        case 51:
            key = .shouldShowBrightnessDownItem
        case 52:
            key = .shouldShowBrightnessUpItem
        case 53:
            key = .shouldShowBrightnessToggleItem
        case 6:
            key = .shouldShowVolumeItem
        case 61:
            key = .shouldShowVolumeDownItem
        case 62:
            key = .shouldShowVolumeUpItem
        case 63:
            key = .shouldShowVolumeToggleItem
        case 64:
            key = .shouldShowVolumeMuteItem
        default:
            return
        }
        Defaults[key] = checkbox.state == .on
        loadCheckboxState()
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadControlCenterWidget, object: nil)
    }
    
}
