//
//  AppCoodrinator.swift
//  Voice Recorder
//
//  Created by Egor on 6/13/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import UIKit

final class AppCoordinator {

    let window: UIWindow
    let rootNavigationController = UINavigationController()

    var recordingService = MicrophoneRecorder()
    var storageService = CoreDataStorage.shared
    var audioSplitter = AudioSplitter()

    required init(_ window: UIWindow) {
        self.window = window
    }

    func openInitialScreen() {
        let viewModel = RecordingViewModel(recorder: recordingService,
                                           storage: storageService,
                                           audioSplitter: audioSplitter)
        let recordingController = RecordingViewController(viewModel)

        rootNavigationController.setViewControllers([recordingController], animated: false)
        window.rootViewController = rootNavigationController
        window.makeKeyAndVisible()
    }
}
