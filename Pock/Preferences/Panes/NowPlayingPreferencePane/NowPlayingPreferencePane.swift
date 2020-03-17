//
//  NowPlayingPreferencePane.swift
//  Pock
//
//  Created by Pierluigi Galdi on 14/12/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

class NowPlayingPreferencePane: NSViewController, PreferencePane {

    /// Preferenceable
    var preferencePaneIdentifier: Identifier = Identifier.now_playing_widget
    let preferencePaneTitle:      String     = "Now Playing".localized
    var toolbarItemIcon:          NSImage {
        let id: String
        if #available(macOS 10.15, *) {
            id = "com.apple.Music"
        }else {
            id = "com.apple.iTunes"
        }
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: id)!
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    /// UI Elements
    @IBOutlet private weak var imagesStackView:         NSStackView!
    @IBOutlet private weak var defaultRadioButton:      NSButton!
    @IBOutlet private weak var onlyInfoRadioButton:     NSButton!
    @IBOutlet private weak var playPauseRadioButton:    NSButton!
    @IBOutlet private weak var hideWidgetIfNoMedia:     NSButton!
    @IBOutlet private weak var animateIconWhilePlaying: NSButton!
    
    override var nibName: NSNib.Name? {
        return "NowPlayingPreferencePane"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch Defaults[.nowPlayingWidgetStyle] {
        case .default:
            defaultRadioButton.state = .on
        case .onlyInfo:
            onlyInfoRadioButton.state = .on
        case .playPause:
            playPauseRadioButton.state = .on
        }
        hideWidgetIfNoMedia.state     = Defaults[.hideNowPlayingIfNoMedia] ? .on : .off
        animateIconWhilePlaying.state = Defaults[.animateIconWhilePlaying] ? .on : .off
        setupImageViewClickGesture()
    }
    
    private func setupImageViewClickGesture() {
        imagesStackView.arrangedSubviews.forEach({
            $0.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(didSelectRadioButton(_:))))
        })
    }
    
    @IBAction private func didSelectRadioButton(_ control: AnyObject) {
        let view = (control as? NSGestureRecognizer)?.view ?? control
        switch view.tag {
        case 0:
            Defaults[.nowPlayingWidgetStyle] = .default
            defaultRadioButton.state   = .on
            onlyInfoRadioButton.state  = .off
            playPauseRadioButton.state = .off
        case 1:
            Defaults[.nowPlayingWidgetStyle] = .onlyInfo
            defaultRadioButton.state   = .off
            onlyInfoRadioButton.state  = .on
            playPauseRadioButton.state = .off
        case 2:
            Defaults[.nowPlayingWidgetStyle] = .playPause
            defaultRadioButton.state   = .off
            onlyInfoRadioButton.state  = .off
            playPauseRadioButton.state = .on
        default:
            return
        }
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNowPlayingWidgetStyle, object: nil)
    }
    
    @IBAction private func didChangeCheckboxState(_ button: NSButton?) {
        guard let button = button else {
            return
        }
        switch button.tag {
        case 0:
            Defaults[.hideNowPlayingIfNoMedia] = button.state == .on
        case 1:
            Defaults[.animateIconWhilePlaying] = button.state == .on
        default:
            return
        }
        NSWorkspace.shared.notificationCenter.post(name: .didChangeNowPlayingWidgetStyle, object: nil)
    }
    
}
