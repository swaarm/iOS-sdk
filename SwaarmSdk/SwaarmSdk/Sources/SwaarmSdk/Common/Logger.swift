import os.log
import Foundation

@objc public class Logger: NSObject {

    private static var isEnabled : Bool = false;

    public static func debug(_ message: String) {
        if (!self.isEnabled) {
            return
        }
        os_log("%@", type: .debug, message)
    }

    public static func setIsEnabled(enabled: Bool) {
        self.isEnabled = enabled;
    }
}
