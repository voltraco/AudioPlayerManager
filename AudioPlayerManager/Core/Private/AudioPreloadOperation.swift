//
//  AudioPreloadOperation.swift
//  AudioPlayerManager
//
//  Created by Przemyslaw Bobak on 07/11/2017.
//  Copyright © 2017 Hans Seiffert. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPreloadOperation: Operation {

    // Initialized properties
    let asset: AVAsset
    let item: AVPlayerItem
    let track: AudioTrack
    let player:AVPlayer
    let queue: OperationQueue

    init(track: AudioTrack, player:AVPlayer, queue:OperationQueue) {
        self.item = track.getPlayerItem()!
        self.asset = self.item.asset
        self.track = track
        self.player = player
        self.queue = queue
    }

    override func main() {
        if self.isCancelled {
            return
        }
        self.queue.isSuspended = true
        self.loadValuesAsynchronously(asset: asset, keys: ["duration", "tracks", "playable"])
    }

    func loadValuesAsynchronously(asset:AVAsset, keys:[String]) {
        asset.loadValuesAsynchronously(forKeys: keys, completionHandler: {
            var loaded = true
            for key in keys {
                var error: NSError?
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed || status == .cancelled {
                    Log("[trackLoadedAsynchronously] Playback failed or have been cancelled")
                    loaded = false
                } else if status == .loading {
                    loaded = false
                    self.loadValuesAsynchronously(asset: asset, keys: keys)
                }
            }

            if loaded {
                if self.isCancelled {
                    self.queue.isSuspended = false
                    return
                }
                let deadlineTime = DispatchTime.now() + .seconds(1)

                DispatchQueue.main.async {
                    Log("[trackLoadedAsynchronously] Playback starting…")
                    self.track.prepareForPlaying(self.item)
                    self.player.replaceCurrentItem(with: self.item)

                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                        self.queue.isSuspended = false
                    }
                }
            }
        })
    }
}
