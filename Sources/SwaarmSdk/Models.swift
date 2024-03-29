import Foundation

struct IosPurchaseValidation: Codable {
    var receipt: String
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
    var advertisingId: String?
    var currency: String?
    var iosPurchaseValidation: IosPurchaseValidation?
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
