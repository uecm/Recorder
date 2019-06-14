//
//  MicrophoneRecording.swift
//  Voice Recorder
//
//  Created by Egor on 6/12/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import Foundation

protocol Identifiable: Codable {
    var identifier: String { get }
}

struct MicrophoneRecording: Identifiable {
    var identifier: String
    let url: URL
    let data: Data
    let duration: TimeInterval
    let timestamp: TimeInterval
}
