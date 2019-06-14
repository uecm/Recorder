//
//  DateFormatter.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import Foundation

extension DateFormatter {

    private static var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    static func mediumStyleFormattedString(from date: Date) -> String {
        return mediumDateFormatter.string(from: date)
    }
}

extension DateComponentsFormatter {
    private static var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute ,.second]
        formatter.unitsStyle = .full
        return formatter
    }

    static func timeString(from interval: TimeInterval) -> String {
        return timeFormatter.string(from: interval) ?? ""
    }
}

