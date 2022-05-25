import Foundation

class DateTime {
    
    public static func now() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date);
    }
    
    public static func currentTimeMillis() -> Int64 {
        Int64(NSDate().timeIntervalSince1970 * 1000)
    }
}
