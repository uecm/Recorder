//
//  RecordingViewModel.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import RxSwift
import RxCocoa

protocol RecordingViewModelling: AnyObject {

    var cellDriver: Driver<[MicrophoneRecording]> { get }

    var recordingToggleSubject: PublishSubject<Bool> { get }
    var recordingTimeRelay: BehaviorRelay<TimeInterval> { get }
}

final class RecordingViewModel: RecordingViewModelling {

    private let disposeBag = DisposeBag()
    private let recorder: MicrophoneRecorder
    private let storage: DataStorage
    private let audioSplitter: AudioSplitter

    private let recordingsSubject = BehaviorSubject<[MicrophoneRecording]>(value: [])

    var recordingToggleSubject = PublishSubject<Bool>()

    var recordingTimeRelay: BehaviorRelay<TimeInterval> {
        return recorder.recordingTime
    }

    var cellDriver: Driver<[MicrophoneRecording]> {
        return recordingsSubject.asDriver(onErrorJustReturn: [])
    }

    required init(recorder: MicrophoneRecorder, storage: DataStorage, audioSplitter: AudioSplitter) {
        self.recorder = recorder
        self.storage = storage
        self.audioSplitter = audioSplitter
        
        recordingToggleSubject
            .bind { shouldRecord in shouldRecord ? self.startRecording() : self.stopRecording() }
            .disposed(by: disposeBag)

        storage
            .loadObservableEntries(of: MicrophoneRecording.self)
            .subscribe(recordingsSubject)
            .disposed(by: disposeBag)
    }

    private func startRecording() {
        recorder.record().subscribe(onSuccess: { recording in
            // Saving segments
           self.audioSplitter.splitAudio(
                from: recording.url,
                intoNumberOfChunks: 3,
                sharingPrefix: DateFormatter.mediumStyleFormattedString(from: Date())) { [weak self] urls in
                    self?.storage.store(recording)
            }
        }, onError: { error in

        }).disposed(by: disposeBag)
    }

    private func stopRecording() {
        recorder.stopRecording().subscribe(onCompleted: {

        }, onError: { error in

        }).disposed(by: disposeBag)
    }
}
