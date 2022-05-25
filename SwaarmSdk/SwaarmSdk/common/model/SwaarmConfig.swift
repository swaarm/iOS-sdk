import Foundation

@objc public class SwaarmConfig: NSObject {
    let appToken: String
    let eventIngressHostname: String
    
    @objc public init(appToken: String, eventIngressHostname: String) {
        self.appToken = appToken
        self.eventIngressHostname = eventIngressHostname
    }
    
    public func isAppTokenValid() -> Bool {
        !appToken.isEmpty
    }
    
    public func isEvenIngressDomainValid() -> Bool {
        !eventIngressHostname.isEmpty
    }
}
