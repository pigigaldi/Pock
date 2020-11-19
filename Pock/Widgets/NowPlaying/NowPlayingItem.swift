//
//  NowPlayingItem.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

class NowPlayingItem {
    /// Data
    public var appBundleIdentifier: String?
    public var title:               String?
    public var album:               String?
    public var artist:              String?
    public var isPlaying:           Bool = false
    public var image: Data?
    
}
