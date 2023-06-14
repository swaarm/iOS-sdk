import os.log

import Foundation

extension OSLog {
    private static var subsystem = "com.swaarm"

    static let viewCycle = OSLog(subsystem: subsystem, category: "sdk")
}
