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
import LoginServiceKit

final class GeneralPreferencePane: NSViewController, PreferencePane {
    
    /// UI
    @IBOutlet weak var versionLabel:             NSTextField!
    @IBOutlet weak var launchAtLoginCheckbox:    NSButton!
    @IBOutlet weak var enableAutomaticUpdates:   NSButton!
    @IBOutlet weak var checkForUpdatesButton:    NSButton!
	@IBOutlet weak var allowBlankTouchBar:		 NSButton!
	@IBOutlet weak var enableMouseSupport:       NSButton!
	@IBOutlet weak var showTrackingArea:		 NSButton!
    
    /// Updates
    var newVersionAvailable: (String, URL)?
	
    /// Preferenceable
    var preferencePaneIdentifier: Preferences.PaneIdentifier = Preferences.PaneIdentifier.general
    let preferencePaneTitle:      String                     = "General".localized
    let toolbarItemIcon:          NSImage                    = NSImage(named: NSImage.preferencesGeneralName)!
    
    override var nibName: NSNib.Name? {
        return "GeneralPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.superview?.wantsLayer = true
        self.view.wantsLayer = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadVersionNumber()
        self.setupCheckboxes()
        if let newVersionNumber = self.newVersionAvailable?.0, let newVersionDownloadURL = self.newVersionAvailable?.1 {
            self.showNewVersionAlert(versionNumber: newVersionNumber, downloadURL: newVersionDownloadURL)
            self.newVersionAvailable = nil
        }
    }
    
    private func loadVersionNumber() {
		self.versionLabel.stringValue = PockUpdater.appVersion
    }
    
    private func setupCheckboxes() {
        self.enableAutomaticUpdates.state = Defaults[.enableAutomaticUpdates]   ? .on : .off
        self.launchAtLoginCheckbox.state  = LoginServiceKit.isExistLoginItems() ? .on : .off
		self.allowBlankTouchBar.state	  = Defaults[.allowBlankTouchBar]		? .on : .off
		self.enableMouseSupport.state	  = Defaults[.enableMouseSupport]       ? .on : .off
		self.showTrackingArea.state		  = Defaults[.showMouseTrackingArea]	? .on : .off
		self.showTrackingArea.isEnabled   = Defaults[.enableMouseSupport]
    }
	
	@IBAction private func didChangeOptions(for button: NSButton) {
		switch button {
		case allowBlankTouchBar:
			Defaults[.allowBlankTouchBar] = button.state == .on
			NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
			
		case launchAtLoginCheckbox:
			if button.state == .on {
				LoginServiceKit.addLoginItems()
			}else {
				LoginServiceKit.removeLoginItems()
			}
			
		case enableMouseSupport:
			showTrackingArea.isEnabled 	  = button.state == .on
			Defaults[.enableMouseSupport] = button.state == .on
			NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
			
		case showTrackingArea:
			Defaults[.showMouseTrackingArea] = button.state == .on
			NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
			
		case enableAutomaticUpdates:
			Defaults[.enableAutomaticUpdates] = button.state == .on
			NSWorkspace.shared.notificationCenter.post(name: .shouldEnableAutomaticUpdates, object: nil)
			
		default:
			return
		}
	}
    
    @IBAction private func checkForUpdates(_ sender: NSButton) {
        self.checkForUpdatesButton.isEnabled = false
        self.checkForUpdatesButton.title     = "Checking…".localized
        
        self.hasLatestVersion(completion: { [weak self] latestVersion, latestVersionDownloadURL in
            if let latestVersion = latestVersion, let latestVersionDownloadURL = latestVersionDownloadURL {
                self?.showNewVersionAlert(versionNumber: latestVersion, downloadURL: latestVersionDownloadURL)
            }else {
				self?.showAlert(title: "Installed version".localized + ": \(PockUpdater.appVersion)", message: "Already on latest version".localized)
            }
            async { [weak self] in
                self?.checkForUpdatesButton.isEnabled = true
                self?.checkForUpdatesButton.title     = "Check for updates".localized
            }
        })
    }
}

extension GeneralPreferencePane {
    func showNewVersionAlert(versionNumber: String, downloadURL: URL) {
        self.showAlert(title:      "New version available!".localized,
                       message:    "Do you want to download version".localized + " \"\(versionNumber)\" " + "now?".localized,
            buttons:    ["Download".localized, "Later".localized],
            completion: { modalResponse in if modalResponse == .alertFirstButtonReturn { NSWorkspace.shared.open(downloadURL) }
        })
    }
    
    private func showAlert(title: String, message: String, buttons: [String] = [], completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        async { [weak self] in
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
    
    struct APIUpdateResponse: Codable {
        let version_number: String
        let download_link:  String
    }
    
    func hasLatestVersion(completion: @escaping (String?, URL?) -> Void) {
		PockUpdater.default.fetchNewVersions(ignoreCache: true) { versions in
			guard let core = versions?.core else {
				completion(nil, nil)
				return
			}
			guard PockUpdater.appVersion < core.name else {
				NSLog("[Pock]: Already on latest version: \(PockUpdater.appVersion)")
				URLSession.shared.finishTasksAndInvalidate()
				completion(nil, nil)
				return
			}
			NSLog("[Pock]: New version available: \(core.name)")
			URLSession.shared.finishTasksAndInvalidate()
			completion(core.name, core.link)
		}
	}
}

