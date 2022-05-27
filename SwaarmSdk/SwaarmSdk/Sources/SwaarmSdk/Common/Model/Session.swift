import Foundation

public class Session {
    let start: String
    let sessionId: String
    var userId: String?

    init() {
        self.start = DateTime.now()
        self.sessionId = UUID().uuidString
    }
    
    public func setUserId(userId: String) {
      self.userId = userId
    }
}
