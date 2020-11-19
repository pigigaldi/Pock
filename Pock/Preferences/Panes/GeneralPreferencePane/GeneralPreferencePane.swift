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
    @IBOutlet weak var versionLabel:                       NSTextField!
    @IBOutlet weak var hideControlStripCheckbox:           NSButton!
    @IBOutlet weak var launchAtLoginCheckbox:              NSButton!
    @IBOutlet weak var enableAutomaticUpdates:             NSButton!
    @IBOutlet weak var checkForUpdatesButton:              NSButton!
    
    /// Endpoint
    #if DEBUG
    private let latestVersionURLString: String = "https://pock.dev/api/dev/latestRelease.json"
    #else
    private let latestVersionURLString: String = "https://pock.dev/api/latestRelease.json"
    #endif
    
    /// Updates
    var newVersionAvailable: (String, URL)?
    
    /// Core
    private static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Preferenceable
    var preferencePaneIdentifier: Preferences.PaneIdentifier = Preferences.PaneIdentifier.general
    let preferencePaneTitle:      String     = "General".localized
    let toolbarItemIcon:          NSImage    = NSImage(named: NSImage.preferencesGeneralName)!
    
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
        self.versionLabel.stringValue = GeneralPreferencePane.appVersion
    }
    
    private func setupCheckboxes() {
        self.hideControlStripCheckbox.state = Defaults[.hideControlStrip]              ? .on : .off
        self.enableAutomaticUpdates.state   = Defaults[.enableAutomaticUpdates]        ? .on : .off
        self.launchAtLoginCheckbox.state    = LoginServiceKit.isExistLoginItems()      ? .on : .off
    }
    
    @IBAction private func didChangeHideControlStripValue(button: NSButton) {
        Defaults[.hideControlStrip] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldReloadPock, object: nil)
    }
    
    @IBAction private func didChangeLaunchAtLoginValue(button: NSButton) {
        switch button.state {
        case .on:
            LoginServiceKit.addLoginItems()
        case .off:
            LoginServiceKit.removeLoginItems()
        default:
            return
        }
    }
    
    @IBAction private func didChangeEnableAutomaticUpdates(button: NSButton) {
        Defaults[.enableAutomaticUpdates] = button.state == .on
        NSWorkspace.shared.notificationCenter.post(name: .shouldEnableAutomaticUpdates, object: nil)
    }
    
    @IBAction private func checkForUpdates(_ sender: NSButton) {
        self.checkForUpdatesButton.isEnabled = false
        self.checkForUpdatesButton.title     = "Checking…".localized
        
        self.hasLatestVersion(completion: { [weak self] latestVersion, latestVersionDownloadURL in
            if let latestVersion = latestVersion, let latestVersionDownloadURL = latestVersionDownloadURL {
                self?.showNewVersionAlert(versionNumber: latestVersion, downloadURL: latestVersionDownloadURL)
            }else {
                self?.showAlert(title: "Installed version".localized + ": \(GeneralPreferencePane.appVersion)", message: "Already on latest version".localized)
            }
            DispatchQueue.main.async { [weak self] in
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
    
    struct APIUpdateResponse: Codable {
        let version_number: String
        let download_link:  String
    }
    
    func hasLatestVersion(completion: @escaping (String?, URL?) -> Void) {
        let latestVersionURL: URL = URL(string: latestVersionURLString)!
        let request = URLRequest(url: latestVersionURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        URLSession.shared.invalidateAndCancel()
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data  = data,
            let apiResponse = try? JSONDecoder().decode(APIUpdateResponse.self, from: data),
            let downloadURL = URL(string: apiResponse.download_link),
            GeneralPreferencePane.appVersion < apiResponse.version_number else {
                NSLog("[Pock]: Already on latest version: \(GeneralPreferencePane.appVersion)")
                URLSession.shared.finishTasksAndInvalidate()
                completion(nil, nil)
                return
            }
            NSLog("[Pock]: New version available: \(apiResponse.version_number)")
            URLSession.shared.finishTasksAndInvalidate()
            completion(apiResponse.version_number, downloadURL)
        }).resume()
    }
}

