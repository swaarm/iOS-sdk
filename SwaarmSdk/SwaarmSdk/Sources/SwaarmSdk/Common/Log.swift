import os.log

import Foundation

extension OSLog {
    private static var subsystem = "WEQ"

    static let viewCycle = OSLog(subsystem: subsystem, category: "sdk")
}