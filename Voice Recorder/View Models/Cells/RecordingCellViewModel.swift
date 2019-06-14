//
//  RecordingCellViewModel.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol RecordingCellViewModelling {

    var progress: BehaviorRelay<Float> { get }
    var playbackToggleSubject: PublishSubject<Bool> { get }
    var deleteSubject: PublishSubject<Void> { get }

    var identifier: String { get }
    var creationDate: String { get }
    var duration: String { get }
}

final class RecordingCellViewModel: RecordingCellViewModelling {

    var playbackToggleSubject = PublishSubject<Bool>()
    var deleteSubject = PublishSubject<Void>()
    var progress = BehaviorRelay<Float>(value: 0.0)

    let disposeBag = DisposeBag()

    // got to move them to the more suitable place
    let storage = CoreDataStorage.shared
    let audioPlayer = AudioPlayer.shared

    var identifier: String
    var creationDate: String
    var duration: String

    init(_ recording: MicrophoneRecording) {
        identifier = recording.identifier
        duration = DateComponentsFormatter.timeString(from: recording.duration)

        let date = Date(timeIntervalSinceReferenceDate: recording.timestamp)
        creationDate = DateFormatter.mediumStyleFormattedString(from: date)

        playbackToggleSubject
            .bind { shouldPlay in
                if shouldPlay {
                    FileManager.default.createFile(atPath: recording.url.path,
                                                   contents: recording.data,
                                                   attributes: nil)
                    self.audioPlayer.playAudio(at: recording.url, duration: recording.duration)
                        .subscribe(onNext: { (progress) in
                            self.progress.accept(progress)
                        }, onCompleted: {
                            self.progress.accept(0.0)
                        })
                        .disposed(by: self.disposeBag)
                } else {
                    self.audioPlayer.stopAudio()
                }
            }
            .disposed(by: disposeBag)

        deleteSubject
            .bind { self.storage.delete(recording) }
            .disposed(by: disposeBag)
    }
}
