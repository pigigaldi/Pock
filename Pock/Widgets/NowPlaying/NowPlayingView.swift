//
//  NowPlayingView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 14/12/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

fileprivate let playIconName  = NSImage.touchBarPlayTemplateName
fileprivate let pauseIconName = NSImage.touchBarPauseTemplateName
fileprivate let previousIcon = NSImage(named: NSImage.touchBarRewindTemplateName)!
fileprivate let nextIcon     = NSImage(named: NSImage.touchBarFastForwardTemplateName)!

class NowPlayingView: PKView {
    
    /// UI
    private let stackView: NSStackView = NSStackView(frame: .zero)
    
    /// Contents UI
    private var itemView:        NowPlayingItemView?
    private var playPauseButton: NSButton?
    private var previousButton:  NSButton {
        let button = NSButton(image: previousIcon, target: self, action: #selector(skipToPreviousItem))
        button.bezelColor = .black
        button.snp.makeConstraints({ m in
            m.width.equalTo(32)
        })
        return button
    }
    private var nextButton: NSButton {
        let button = NSButton(image: nextIcon, target: self, action: #selector(skipToNextItem))
        button.bezelColor = .black
        button.snp.makeConstraints({ m in
            m.width.equalTo(32)
        })
        return button
    }
    
    /// Core
    private var shouldHideWidget: Bool {
        if Defaults[.hideNowPlayingIfNoMedia] {
            return item?.appBundleIdentifier == nil
        }
        return false
    }
    
    /// Styles
    public var style: NowPlayingWidgetStyle = Defaults[.nowPlayingWidgetStyle] {
        didSet {
            configureUIElements()
        }
    }
    
    /// Data
    public var item: NowPlayingItem? = nil {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if self == nil {
                    return
                }
                self?.updateContentViews()
            }
        }
    }
    
    /// Overrides
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 30))
        self.configureStackView()
        self.configureUIElements()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureStackView()
        self.configureUIElements()
    }
    
    /// Configuration
    private func configureStackView() {
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = 6
        addSubview(stackView)
        stackView.snp.makeConstraints({ m in
            m.left.top.right.bottom.equalToSuperview()
        })
    }
    
    private func configureUIElements() {
        removeArrangedSubviews()
        switch style {
        case .default, .onlyInfo:
            guard itemView == nil else { break }
            itemView = NowPlayingItemView(frame: .zero, leftToRight: true)
            itemView?.nowPLayingItem = item
            setupGestureHandlers()
        case .playPause:
            guard playPauseButton == nil else { break }
            let icon = NSImage(named: item?.isPlaying ?? false ? pauseIconName : playIconName)!
            playPauseButton = NSButton(image: icon, target: self, action: #selector(togglePlayPause))
            playPauseButton?.bezelColor = .black
            playPauseButton?.snp.makeConstraints({ m in
                m.width.equalTo(32)
            })
        }
        addArrangedSubviews()
    }
    
    private func removeArrangedSubviews() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        playPauseButton = nil
        itemView        = nil
    }
    
    private func addArrangedSubviews() {
        guard !shouldHideWidget else {
            return
        }
        let views: [NSView]
        switch style {
        case .default:
            views = [previousButton, itemView!, nextButton]
        case .onlyInfo:
            views = [itemView!]
        case .playPause:
            views = [previousButton, playPauseButton!, nextButton]
        }
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }
    
    private func setupGestureHandlers() {
        switch self.style {
        case .playPause:
            itemView?.didTap        = nil
            itemView?.didSwipeLeft  = nil
            itemView?.didSwipeRight = nil
        case .default, .onlyInfo:
            itemView?.didTap        = { [unowned self] in self.togglePlayPause()    }
            itemView?.didSwipeLeft  = { [unowned self] in self.skipToPreviousItem() }
            itemView?.didSwipeRight = { [unowned self] in self.skipToNextItem()     }
        }
    }
    
    /// Update
    private func updateContentViews() {
        guard !shouldHideWidget else {
            removeArrangedSubviews()
            return
        }
        if stackView.arrangedSubviews.isEmpty {
            configureUIElements()
        }
        switch style {
        case .default, .onlyInfo:
            itemView?.nowPLayingItem = item
        case .playPause:
            playPauseButton?.image = NSImage(named: item?.isPlaying ?? false ? pauseIconName : playIconName)!
        }
    }
    
    /// Handlers
    @objc private func togglePlayPause() {
        NowPlayingHelper.shared.togglePlayingState()
    }
    
    @objc private func skipToNextItem() {
        NowPlayingHelper.shared.skipToNextTrack()
    }
    
    @objc private func skipToPreviousItem() {
        NowPlayingHelper.shared.skipToPreviousTrack()
    }
    
    override func didLongPressHandler() {
        guard let id = item?.appBundleIdentifier else {
            return
        }
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: id,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }
    
}
