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

struct TrackingEvent: Codable {
    var id: String
    var typeId: String?
    var aggregatedValue: Double
    var customValue: String
    var revenue: Double
    var vendorId: String
    var clientTime: String
    var osv: String
}

struct TrackingEventBatch: Codable {
    var events: [TrackingEvent]
    var time: String
}

struct ConfiguredBreakpoint: Codable {
    var viewName: String
    var eventType: String
}

struct ConfiguredBreakpoints: Codable {
    var viewBreakpoints: [ConfiguredBreakpoint]
}

struct BreakpointData: Codable {
    var name: String
    var screenshot: Data
}

struct Breakpoint: Codable {
    var type: String
    var data: BreakpointData
}
