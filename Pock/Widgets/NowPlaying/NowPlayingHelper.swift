//
//  NowPlayingHelper.swift
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import Defaults

class NowPlayingHelper {
    
    /// Core
    public static let shared: NowPlayingHelper = NowPlayingHelper()
    public static let kNowPlayingItemDidChange: Notification.Name = Notification.Name(rawValue: "kNowPlayingItemDidChange")
    
    /// Data
    public var nowPlayingItem: NowPlayingItem = NowPlayingItem()
    
    private init() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.global(qos: .utility))
        registerForNotifications()
        updateCurrentPlayingApp()
        updateMediaContent()
        updateCurrentPlayingState()
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateCurrentPlayingApp),
                                               name: NSNotification.Name.mrMediaRemoteNowPlayingApplicationDidChange,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name(rawValue: kMRMediaRemoteNowPlayingApplicationClientStateDidChange),
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name.mrNowPlayingPlaybackQueueChanged,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMediaContent),
                                               name: NSNotification.Name.mrPlaybackQueueContentItemsChanged,
                                               object: nil
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateCurrentPlayingState),
                                               name: NSNotification.Name.mrMediaRemoteNowPlayingApplicationIsPlayingDidChange,
                                               object: nil
        )
    }
    
    @objc private func updateCurrentPlayingApp() {
        MRMediaRemoteGetNowPlayingClients(DispatchQueue.global(qos: .utility), { [weak self] clients in
            if let info = (clients as? [Any])?.last {
                if let appBundleIdentifier = MRNowPlayingClientGetBundleIdentifier(info) {
                    self?.nowPlayingItem.appBundleIdentifier = appBundleIdentifier
                }else if let appBundleIdentifier = MRNowPlayingClientGetParentAppBundleIdentifier(info) {
                    self?.nowPlayingItem.appBundleIdentifier = appBundleIdentifier
                }else {
                    self?.nowPlayingItem.appBundleIdentifier = nil
                }
            }else {
                self?.nowPlayingItem.appBundleIdentifier = nil
                self?.nowPlayingItem.isPlaying = false
                self?.nowPlayingItem.album  = nil
                self?.nowPlayingItem.artist = nil
                self?.nowPlayingItem.title  = nil
            }
            self?.lastNowPlayingItem?.appBundleIdentifier = self?.nowPlayingItem.appBundleIdentifier
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        })
    }
    
    
    private var artworkAPITask: URLSessionTask?
    private var artworkDownloadTask: URLSessionTask?
    
    var cachedAlbumArtName: String? = nil
    var cachedAlbumArt: Data? = nil
    
    // credit: https://github.com/musa11971/Music-Bar
    func updateArtwork(search: String, completionHandler: @escaping (Data?) -> Void) {
        
        if (cachedAlbumArtName == search) {
            completionHandler(cachedAlbumArt)
            return
        }
        
        
        // Destroy tasks, if any were already busy
        if let previousAPITask = artworkAPITask {
            previousAPITask.cancel()
        }
        
        if let previousDownloadTask = artworkDownloadTask {
            previousDownloadTask.cancel()
        }
        
        // Start fetching artwork
        artworkAPITask = URLSession.fetchJSON(fromURL: URL(string: "https://itunes.apple.com/search?term=\(search)&entity=song&limit=1")!) { (data, json, error) in
            if error != nil {
                print("Could not get artwork")
                completionHandler(nil)
                return
            }

            if let json = json as? [String: Any] {
                if let results = json["results"] as? [[String: Any]] {
                    if results.count >= 1, let imgURL = results[0]["artworkUrl100"] as? String {
                        
                        // Create the URL
                        let url = URL(string: imgURL)!
                        
                        // Download the artwork
                        self.artworkDownloadTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                            
                            if error != nil {
                                completionHandler(nil)
                                return
                            }

                            DispatchQueue.main.async {
                                self.cachedAlbumArtName = search
                                self.cachedAlbumArt = data
                                // Set the artwork to the image
                                completionHandler(self.cachedAlbumArt)
                            }
                        })
                            
                        self.artworkDownloadTask!.resume()
                    }
                    else {
                        completionHandler(nil)
                    }
                }
                else {
                    completionHandler(nil)
                }
            }
            else {
                completionHandler(nil)
            }
        }
        
        artworkAPITask!.resume()
    }
    
    
    
    var albumArtFallbackTimer: Timer? = nil
    
    var lastUIUpdateNanos: UInt64? = nil
    
    // flag to indicate whether to fallback to network icon
    var timesLeftTryUpdatingMediaContentManually: Int = 2

    
    @objc func fireTimerIconFailed() {
        albumArtFallbackTimer = nil
        if (self.nowPlayingItem.image == nil) {
            self.updateArtwork(search: "\(self.nowPlayingItem.title ?? "") \(self.nowPlayingItem.artist ?? "")".replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) { image in
                if (image != nil) {
                    self.nowPlayingItem.image = image
                    NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
                }
            }
        }
    }
    
    // added this variable because `updateMediaContent` is called many times with different information
    var lastNowPlayingItem: NowPlayingItem?
    
    func setupTimer() {
        if self.albumArtFallbackTimer == nil {
            // fallback to network artwork after 20 seconds
            DispatchQueue.main.async {
                if (self.timesLeftTryUpdatingMediaContentManually <= 0) {
                    // we have tried getting the artwork with official api manually but it didn't work, get it from the iTunes API
                    self.timesLeftTryUpdatingMediaContentManually = 2
                    self.albumArtFallbackTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(NowPlayingHelper.fireTimerIconFailed), userInfo: nil, repeats: false)
                } else {
                    let timeInterval: Double = self.timesLeftTryUpdatingMediaContentManually == 2 ? 1.5 : 8.0
                    
                    self.timesLeftTryUpdatingMediaContentManually -= 1
                    self.albumArtFallbackTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(NowPlayingHelper.updateMediaContent(sender:)), userInfo: ["fromTimer": true], repeats: false)
                }
            }
        }
    }
    
    func updateUI(withTimer: Bool) {
        self.lastUIUpdateNanos = DispatchTime.now().uptimeNanoseconds
        NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        if withTimer {
            if self.albumArtFallbackTimer != nil {
                self.albumArtFallbackTimer?.invalidate()
                self.albumArtFallbackTimer = nil
                if let previousAPITask = artworkAPITask {
                    previousAPITask.cancel()
                }
                
                if let previousDownloadTask = artworkDownloadTask {
                    previousDownloadTask.cancel()
                }
            }
            self.timesLeftTryUpdatingMediaContentManually = 2
            setupTimer()
        }
    }
    
    @objc private func updateMediaContent(sender: Any? = nil) {
        // indicates whether we need to run another step of the timer
        var rerunTimer = false
        if sender != nil {
            if (sender is Timer) {
                let dict = (sender as! Timer).userInfo as? NSDictionary
                if ((dict?["fromTimer"] as? Bool) == true) {
                    self.albumArtFallbackTimer = nil
                    rerunTimer = true
                }
            }
        }
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { [weak self] info in
            if self == nil {
                return
            }
            var initialRun = false
            if (self?.lastNowPlayingItem == nil) {
                // `lastNowPlayingItem` is still nil it's the first time `updateMediaContent` is being run
                self?.lastNowPlayingItem = self?.nowPlayingItem
                initialRun = true
            }
            self?.lastNowPlayingItem?.title  = info?[kMRMediaRemoteNowPlayingInfoTitle]  as? String
            self?.lastNowPlayingItem?.album  = info?[kMRMediaRemoteNowPlayingInfoAlbum]  as? String
            self?.lastNowPlayingItem?.artist = info?[kMRMediaRemoteNowPlayingInfoArtist] as? String
            if info == nil {
                self?.lastNowPlayingItem?.isPlaying = false
            }
            var containsImage = false
            if Defaults[.showArtwork] {
                self?.lastNowPlayingItem?.image = info?[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data
                let url = info?[kMRMediaRemoteNowPlayingInfoArtworkURL] as? String
                if (self?.cachedAlbumArtName == "\(self?.lastNowPlayingItem?.title ?? "") \(self?.lastNowPlayingItem?.artist ?? "")".replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!) {
                    self?.lastNowPlayingItem?.image = self?.cachedAlbumArt
                }
                
                containsImage = self?.lastNowPlayingItem?.image != nil
                if (!isProd) {
                    print("contains image: \(containsImage)")
                }
            }

            if (!initialRun &&
                self?.lastNowPlayingItem?.title == self?.nowPlayingItem.title &&
                self?.lastNowPlayingItem?.album == self?.nowPlayingItem.album &&
                self?.lastNowPlayingItem?.artist == self?.nowPlayingItem.artist &&
                self?.lastNowPlayingItem?.appBundleIdentifier == self?.nowPlayingItem.appBundleIdentifier) {
                if Defaults[.showArtwork] {
                    // if everything is the same compare image data
                    if (self?.lastNowPlayingItem?.image != self?.nowPlayingItem.image) {
                        self?.nowPlayingItem.image = self?.lastNowPlayingItem?.image
                        // if the new image data isn't nil cancel the network fallback timer
                        if (self?.nowPlayingItem.image != nil) {
                            self?.albumArtFallbackTimer?.invalidate()
                            self?.albumArtFallbackTimer = nil
                        }
                        self?.timesLeftTryUpdatingMediaContentManually = 2
                        rerunTimer = false
                        // if image data is different update the UI
                        if let lastUIUpdateNanosVerified = self?.lastUIUpdateNanos {
                            if (DispatchTime.now().uptimeNanoseconds - lastUIUpdateNanosVerified < 500*1000000) {
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+DispatchTimeInterval.milliseconds(500)) {
                                    self?.updateUI(withTimer: false)
                                }
                            } else {
                                self?.updateUI(withTimer: false)
                            }
                        } else {
                            self?.updateUI(withTimer: false)
                        }
                    }
                }
            } else {
                if let nowPlayingLocal = self?.lastNowPlayingItem {
                    // create a copy of the `nowPlayingItem` item in order to compare
                    self?.nowPlayingItem = NowPlayingItem()
                    self?.nowPlayingItem.album = nowPlayingLocal.album
                    self?.nowPlayingItem.artist = nowPlayingLocal.artist
                    self?.nowPlayingItem.appBundleIdentifier = nowPlayingLocal.appBundleIdentifier
                    self?.nowPlayingItem.title = nowPlayingLocal.title
                    self?.nowPlayingItem.isPlaying = nowPlayingLocal.isPlaying
                    self?.lastUIUpdateNanos = DispatchTime.now().uptimeNanoseconds
                    
                    if Defaults[.showArtwork] {
                        self?.nowPlayingItem.image = nowPlayingLocal.image
                        if let lastUIUpdateNanosVerified = self?.lastUIUpdateNanos {
                            if (DispatchTime.now().uptimeNanoseconds - lastUIUpdateNanosVerified < 500*1000000) {
                                if (DispatchTime.now().uptimeNanoseconds - lastUIUpdateNanosVerified < 500*1000000) {
                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+DispatchTimeInterval.milliseconds(500)) {
                                        self?.updateUI(withTimer: !containsImage)
                                    }
                                }
                            } else {
                                self?.updateUI(withTimer: !containsImage)
                            }
                        } else {
                            self?.updateUI(withTimer: !containsImage)
                        }
                    } else {
                        self?.updateUI(withTimer: false)
                    }
                }
            }
            if (rerunTimer) {
                self?.setupTimer()
            }
        })
    }
    
    @objc private func updateCurrentPlayingState() {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main, {[weak self] isPlaying in
            if self?.nowPlayingItem.appBundleIdentifier == nil {
                self?.nowPlayingItem.isPlaying = false
            }else {
                self?.nowPlayingItem.isPlaying = isPlaying
            }
            self?.lastNowPlayingItem?.isPlaying = self?.nowPlayingItem.isPlaying == true
            NotificationCenter.default.post(name: NowPlayingHelper.kNowPlayingItemDidChange, object: nil)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension NowPlayingHelper {
    
    public func togglePlayingState() {
        MRMediaRemoteSendCommand(kMRTogglePlayPause, nil)
    }
    
    public func skipToNextTrack() {
        MRMediaRemoteSendCommand(kMRNextTrack, nil)
    }
    
    public func skipToPreviousTrack() {
        MRMediaRemoteSendCommand(kMRPreviousTrack, nil)
    }
    
}

extension URLSession {
      static func fetchJSON(fromURL url: URL, completionHandler: @escaping (Data?, Any?, Error?) -> Void) -> URLSessionTask {
          let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
              // Error occurred during request
              if error != nil {
                  completionHandler(nil, nil, error)
                  return
              }
            
            if data == nil {
                completionHandler(nil, nil, NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Invalid data"]))
                return
            }
              
            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)

            if json == nil {
                completionHandler(nil, nil, NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Invalid json"]))
                return
            }
            
            completionHandler(data, json, nil)
          }
          
          return task
      }
  }

