//
//  RecordingViewController.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit

class RecordingViewController: UIViewController {

    let disposeBag = DisposeBag()

    private var button: UIButton!

    let recorder = MicrophoneRecorder()


    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.setTitleColor(.blue, for: [])
        button.sizeToFit()

        view.addSubview(button)

        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        self.button = button

        recorder.isRecording.asDriver(onErrorJustReturn: false)
            .map { $0 == true ? self.stopRecording : self.startRecording }
            .drive(onNext: { next in
                button.rx.tap.bind(onNext: next).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)

        recorder.isRecording.asDriver(onErrorJustReturn: false)
            .map { $0 == true ? "Stop" : "Start" }
            .drive(button.rx.title())
            .disposed(by: disposeBag)

    }

    private func startRecording() {
        recorder.record().subscribe(onSuccess: { recording in

        }, onError: { error in

        }).disposed(by: disposeBag)
    }

    private func stopRecording() {
        recorder.stopRecording().subscribe(onCompleted: {

        }, onError: { error in

        }).disposed(by: disposeBag)
    }

//    func switchRecordState() {
//        recorder.isRecording.flatMapLatest { (value) -> Observable<Any> in
//            print(value)
//            return Observable.empty()
//        }

//            .asDriver(onErrorJustReturn: false).map {
//           [unowned self] isRecording in
//            if isRecording == true {
//                self.recorder.stopRecording().do()
//            } else  {
//                self.recorder.record().do()
//            }
//        }.drive().disposed(by: disposeBag)


//        self.recorder.record().subscribe(onSuccess: { (recording) in
//
//        }, onError: { error in
//
//        }).disposed(by: disposeBag)

//    }
}
