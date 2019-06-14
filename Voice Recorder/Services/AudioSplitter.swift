//
//  AudioSplitter.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import AVFoundation

final class AudioSplitter {

    private var exportGroup: DispatchGroup?

    private var directoryURL: URL {
        return (try? FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true))
            ?? FileManager.default.temporaryDirectory
    }

    func splitAudio(from url: URL,
                    intoNumberOfChunks chunkCount: Int,
                    sharingPrefix prefix: String,
                    completion: (([URL]) -> Void)?) {

        let asset = AVAsset(url: url)
        let exportURL = directoryURL.appendingPathComponent(prefix)

        let duration = CMTimeGetSeconds(asset.duration)
        let chunkDuration = duration / Double(chunkCount)

        var urls: [URL?] = []

        exportGroup = DispatchGroup()

        for i in 0 ..< chunkCount {
            exportGroup?.enter()
            let start = CMTime(seconds: Double(i) * chunkDuration, preferredTimescale: 1)
            let range = CMTimeRange(start: start, duration: CMTime(value: CMTimeValue(chunkDuration), timescale: 1))
            let url = URL(string: exportURL.absoluteString.replacingOccurrences(of: "%", with: "-")
                        + "-part-\(i)")?.appendingPathExtension("m4a")
            urls.append(url)

            exportChunk(from: asset, with: range, at: url) { [weak self] in
                self?.exportGroup?.leave()
            }
        }
        exportGroup?.wait()
        completion?(urls.compactMap { $0 })
    }

    private func exportChunk(from asset: AVAsset, with range: CMTimeRange, at url: URL?, completion: (() -> Void)?) {
        guard
            let url = url,
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                return
        }
        exporter.outputFileType = .m4a
        exporter.timeRange = range
        exporter.outputURL = url
        exporter.exportAsynchronously {
            completion?()
        }
    }


}
