//
//  MicrophoneRecorder.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import RxCocoa
import RxSwift
import AVFoundation

enum MicrophoneRecorderError: Error {
    case permissionNotGranted
    case avSessionFailure
}

final class MicrophoneRecorder: NSObject {

    private var audioSession = AVAudioSession()
    private lazy var recorder: AVAudioRecorder = setupRecorder()
    private let disposeBag = DisposeBag()
    private var observer: Single<MicrophoneRecording>.SingleObserver?

    private(set) var isRecording = BehaviorRelay<Bool>(value: false)

    private var recordingTimer = Observable<Int>.interval(.milliseconds(10), scheduler: MainScheduler.instance)
    private var timerBag: DisposeBag?

    var recordingTime: BehaviorRelay<TimeInterval> = .init(value: 0.0)

    func record() -> Single<MicrophoneRecording> {
        return Single.create { [unowned self] single in
            self.observer = single

            self.audioSession.requestRecordPermission { granted in
                if !granted {
                    single(.error(MicrophoneRecorderError.permissionNotGranted))
                } else {
                    DispatchQueue.main.async {
                        self.setupAudioSession()
                        self.recorder.record(forDuration: self.maxRecordingDuration)
                        self.startTimer()
                        self.isRecording.accept(true)
                    }
                }
            }
            return Disposables.create()
        }
    }

    func stopRecording() -> Completable {
        return Completable.create { [unowned self] completable in
            self.recorder.stop()
            self.isRecording.accept(false)
            do {
                try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                completable(.completed)
            } catch {
                print("Error stopping voice recording: \(error)")
                completable(.error(error))
            }
            return Disposables.create()
        }
    }

    private func setupRecorder() -> AVAudioRecorder {
        var recorder: AVAudioRecorder?
        do {
            recorder = try AVAudioRecorder(url: tempRecordingUrl, settings: recorderSettings)
            recorder?.delegate = self
            recorder?.prepareToRecord()
            isRecording.accept(false)
        } catch {
            print("Error during initializaiton of AVAudioRecorder: \(error)")
        }
        return recorder!
    }

    private func setupAudioSession() {
        let session = self.audioSession
        do {
            try session.setCategory(.record, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch { print("Error occurred while trying to setup audio session: \(error)") }
    }

    // MARK: Timer

    private func startTimer() {
        timerBag = DisposeBag()
        recordingTimer
            .map {
                let value = TimeInterval($0) / 100
                return value < self.maxRecordingDuration ? value : self.maxRecordingDuration
            }
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: 0)
            .drive(recordingTime)
            .disposed(by: timerBag ?? disposeBag)
    }

    private func stopTimer() {
        timerBag = nil
    }

    // MARK: Audio recorder settings

    private var recorderSettings: [String: Int] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    private var tempRecordingUrl: URL {
        let stamp = Date.timeIntervalSinceReferenceDate
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let tempDir = FileManager.default.temporaryDirectory
        return (documentsDir ?? tempDir).appendingPathComponent("temp-recording-\(stamp).aac")
    }

    private var maxRecordingDuration: TimeInterval {
        return 30.0 // seconds
    }
}

// MARK: - AVAudioRecorderDelegate
extension MicrophoneRecorder: AVAudioRecorderDelegate {

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        observer?(.error(MicrophoneRecorderError.avSessionFailure))
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag,
            let recordingData = try? Data(contentsOf: recorder.url) else {
                observer?(.error(MicrophoneRecorderError.avSessionFailure))
                return
        }
        let recording = MicrophoneRecording(
            identifier: UUID().uuidString,
            url: recorder.url,
            data: recordingData,
            duration: recordingTime.value,
            timestamp: Date.timeIntervalSinceReferenceDate
        )
        observer?(.success(recording))
        stopTimer()
    }
}
