//
//  StatusWidgetPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 30/03/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class StatusWidgetPreferencePane: NSViewController, NSTextFieldDelegate, PreferencePane {

    /// UI
    @IBOutlet weak var showWifiItem:                NSButton!
    @IBOutlet weak var showPowerItem:               NSButton!
    @IBOutlet weak var showBatteryIconItem:         NSButton!
    @IBOutlet weak var showBatteryPercentageItem:   NSButton!
    @IBOutlet weak var showDateItem:                NSButton!
    // @IBOutlet weak var showSpotlightItem:           NSButton!
    @IBOutlet weak var timeFormatTextField:         NSTextField!
    
    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.status_widget
    let preferencePaneTitle:      String     = "Status".localized
    var toolbarItemIcon:          NSImage {
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: "com.apple.systempreferences")!
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    override var nibName: NSNib.Name? {
        return "StatusWidgetPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.superview?.wantsLayer = true
        self.view.wantsLayer = true
        self.loadCheckboxState()
        self.timeFormatTextField.delegate = self
        self.timeFormatTextField.stringValue = Defaults[.timeFormatTextField]
    }
    
    private func loadCheckboxState() {
        self.showWifiItem.state              = Defaults[.shouldShowWifiItem]          ? .on : .off
        self.showPowerItem.state             = Defaults[.shouldShowPowerItem]         ? .on : .off
        self.showBatteryIconItem.state       = Defaults[.shouldShowBatteryIcon]       ? .on : .off
        self.showBatteryPercentageItem.state = Defaults[.shouldShowBatteryPercentage] ? .on : .off
        self.showDateItem.state              = Defaults[.shouldShowDateItem]          ? .on : .off
        // self.showSpotlightItem.state         = defaults[.shouldShowSpotlightItem]     ? .on : .off
    }
    
    @IBAction func didChangeCheckboxValue(_ checkbox: NSButton) {
        var key: Defaults.Key<Bool>
        switch checkbox.tag {
        case 1:
            key = .shouldShowWifiItem
        case 2:
            key = .shouldShowPowerItem
        case 21:
            key = .shouldShowBatteryIcon
        case 22:
            key = .shouldShowBatteryPercentage
        case 3:
            key = .shouldShowDateItem
        /* case 4:
            key = .shouldShowSpotlightItem */
        default:
            return
        }
        Defaults[key] = checkbox.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadStatusWidget, object: nil)
    }
    
    @IBAction func openTimeFormatHelpURL(_ sender: NSButton) {
        guard let url = URL(string: "https://www.mowglii.com/itsycal/datetime.html") else { return }
        NSWorkspace.shared.open(url)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        Defaults[.timeFormatTextField] = timeFormatTextField.stringValue
    }
}
