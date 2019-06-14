//
//  AudioPlayer.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import AVFoundation
import RxSwift
import RxCocoa

final class AudioPlayer {

    static let shared = AudioPlayer()

    private var player: AVPlayer?
    private var timeObserverToken: Any?


    func playAudio(at url: URL, duration: TimeInterval) -> Observable<Float> {
        if let player = player, player.timeControlStatus == .playing {
            stopAudio()
        }
        return Observable.create { observer in
            let player = AVPlayer(playerItem: AVPlayerItem(url: url))
            player.volume = 1.0

            let timeScale = CMTimeScale(NSEC_PER_SEC)
            let time = CMTime(seconds: 0.01, preferredTimescale: timeScale)

            self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: time,
                                                               queue: DispatchQueue.main
            ) { time in
                let progress = Float(time.seconds / duration)

                if progress >= 1 {
                    observer.onCompleted()
                } else {
                    observer.onNext(progress)
                }
            }

            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.seek(to: .zero)
            player.play()

            self.player = player

            return Disposables.create()
        }
    }

    func stopAudio() {
        player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        player = nil
    }
}
