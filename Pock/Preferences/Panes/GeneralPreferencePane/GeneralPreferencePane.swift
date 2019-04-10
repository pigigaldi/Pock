//
//  GeneralPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 12/10/2018.
//  Copyright © 2018 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Preferences
import Defaults
import LaunchAtLogin
import Sparkle

final class GeneralPreferencePane: NSViewController, Preferenceable {
    
    /// UI
    @IBOutlet weak var versionLabel:                       NSTextField!
    @IBOutlet weak var notificationBadgeRefreshRatePicker: NSPopUpButton!
    @IBOutlet weak var hideControlStripCheckbox:           NSButton!
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    @IBOutlet weak var checkForUpdatesButton:              NSButton!
    
    /// Core
    private static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Preferenceable
    let toolbarItemTitle: String   = "General"
	let toolbarItemIcon:  NSImage  = NSImage(named: .preferencesGeneral)!

    override var nibName: NSNib.Name? {
        return NSNib.Name("GeneralPreferencePane")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadVersionNumber()
        self.populatePopUpButton()
        self.setupLaunchAtLoginCheckbox()
    }
    
    private func loadVersionNumber() {
        self.versionLabel.stringValue = GeneralPreferencePane.appVersion
    }
    
    private func populatePopUpButton() {
        self.notificationBadgeRefreshRatePicker.removeAllItems()
        self.notificationBadgeRefreshRatePicker.addItems(withTitles: NotificationBadgeRefreshRateKeys.allCases.map({ $0.toString() }))
        self.notificationBadgeRefreshRatePicker.selectItem(withTitle: defaults[.notificationBadgeRefreshInterval].toString())
    }
    
    private func setupLaunchAtLoginCheckbox() {
        self.launchAtLoginCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off
    }
    
    @IBAction private func didSelectNotificationBadgeRefreshRate(_: NSButton) {
        defaults[.notificationBadgeRefreshInterval] = NotificationBadgeRefreshRateKeys.allCases[self.notificationBadgeRefreshRatePicker.indexOfSelectedItem]
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNotificationBadgeRefreshRate, object: nil)
    }
    
    @IBAction private func didChangeLaunchAtLoginValue(button: NSButton) {
        LaunchAtLogin.isEnabled = button.state == .on
    }
    
    @IBAction private func didChangeHideControlStripValue(button: NSButton) {
        defaults[.hideControlStrip] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
    }
    
    @IBAction private func checkForUpdates(_ sender: NSButton) {
        SUUpdater.shared()?.checkForUpdates(sender)
    }
}

extension GeneralPreferencePane {
    
    func showNewVersionAlert(versionNumber: String, downloadURL: URL) {
        self.showAlert(title:      "New version available!",
                       message:    "Do you want to download version \"\(versionNumber)\" now?",
                       buttons:    ["Download", "Later"],
                       completion: { modalResponse in if modalResponse == .alertFirstButtonReturn { NSWorkspace.shared.open(downloadURL) }
        })
    }
    
    private func showAlert(title: String, message: String, buttons: [String] = [], completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let _self = self else { return }
            let alert             = NSAlert()
            alert.alertStyle      = NSAlert.Style.informational
            alert.messageText     = title
            alert.informativeText = message
            for buttonTitle in buttons {
                alert.addButton(withTitle: buttonTitle)
            }
            alert.beginSheetModal(for: _self.view.window!, completionHandler: completion)
        }
    }
    
}
