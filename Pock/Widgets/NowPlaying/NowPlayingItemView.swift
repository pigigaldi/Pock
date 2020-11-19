//
//  NowPlayingItemView.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit
import Defaults

extension String {
    func truncate(length: Int, trailing: String = "…") -> String {
        return self.count > length ? String(self.prefix(length)) + trailing : self
    }
}

class NowPlayingItemView: PKDetailView {
    
    /// Overrideable
    public var didTap: (() -> Void)?
    public var didSwipeLeft: (() -> Void)?
    public var didSwipeRight: (() -> Void)?
    public var didLongPress: (() -> Void)?
    
    /// Data
    public var nowPLayingItem: NowPlayingItem? {
        didSet {
            self.updateContent()
        }
    }
    
    override func didLoad() {
        titleView.numberOfLoop    = 3
        subtitleView.numberOfLoop = 1
        super.didLoad()
    }
    
    private func updateContent() {
        
        var appBundleIdentifier: String = self.nowPLayingItem?.appBundleIdentifier ?? ""
        
        switch (appBundleIdentifier) {
        case "com.apple.WebKit.WebContent":
            appBundleIdentifier = "com.apple.Safari"
        case "com.spotify.client", "com.apple.iTunes", "com.apple.Safari", "com.google.Chrome", "com.netease.163music", "com.tencent.QQMusicMac",
             "com.xiami.macclient", "com.apple.Music":
            break
        default:
            if #available(macOS 10.15, *) {
                appBundleIdentifier = "com.apple.Music"
            }else {
                appBundleIdentifier = "com.apple.iTunes"
            }
        }
        
        let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: appBundleIdentifier)
        
        DispatchQueue.main.async { [weak self] in
            if self == nil {
                return
            }
            if Defaults[.showArtwork], let imageData = self?.nowPLayingItem?.image {
                self?.imageView.image = NSImage(data: imageData)
            } else {
                self?.imageView.image = DockRepository.getIcon(forBundleIdentifier: appBundleIdentifier, orPath: path)
            }
            
            let isPlaying = self?.nowPLayingItem?.isPlaying ?? false
            var title     = self?.nowPLayingItem?.title     ?? "Tap here".localized
            var artist    = self?.nowPLayingItem?.artist    ?? "to play music".localized
            
            if title.isEmpty {
                title = "Missing title".localized
            }
            if artist.isEmpty {
                artist = "Unknown artist".localized
            }
            
            let titleWidth    = (title  as NSString).size(withAttributes: self?.titleView.textFontAttributes    ?? [:]).width
            let subtitleWidth = (artist as NSString).size(withAttributes: self?.subtitleView.textFontAttributes ?? [:]).width
            self?.maxWidth = min(max(titleWidth, subtitleWidth), 80)
            
            self?.titleView.setup(string:    title)
            self?.subtitleView.setup(string: artist)
            
            self?.titleView.speed    = titleWidth    > 80 && isPlaying ? 4 : 0
            self?.subtitleView.speed = subtitleWidth > 80 && isPlaying ? 4 : 0
            
            self?.updateForNowPlayingState()
            self?.updateConstraint()
            self?.layoutSubtreeIfNeeded()
        }
    }
    
    private func updateForNowPlayingState() {
        if Defaults[.animateIconWhilePlaying], self.nowPLayingItem?.isPlaying ?? false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: { [weak self] in
                self?.startBounceAnimation()
            })
        }else {
            self.stopBounceAnimation()
        }
    }
    
    override open func didTapHandler() {
        self.didTap?()
    }
    
    override open func didSwipeLeftHandler() {
        self.didSwipeLeft?()
    }
    
    override open func didSwipeRightHandler() {
        self.didSwipeRight?()
    }
    
    override func didLongPressHandler() {
        self.didLongPress?()
    }
    
}
