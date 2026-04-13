import Foundation

// MARK: - Event Models

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

// MARK: - Breakpoint Models

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

// MARK: - Attribution Models

public struct AttributionData: Codable {
    public var offer: AttributionOffer?
    public var publisher: AttributionPublisher?
    public var ids: AttributionIds?
    public var decision: PostbackDecision?
    public var googleInstallReferrer: GoogleInstallReferrerData?
}

public struct AttributionOffer: Codable {
    public var id: String?
    public var name: String?
    public var lpId: String?
    public var campaignId: String?
    public var campaignName: String?
    public var adGroupId: String?
    public var adGroupName: String?
    public var adId: String?
    public var adName: String?
}

public struct AttributionPublisher: Codable {
    public var id: String?
    public var name: String?
    public var subId: String?
    public var subSubId: String?
    public var site: String?
    public var placement: String?
    public var creative: String?
    public var app: String?
    public var appId: String?
    public var unique1: String?
    public var unique2: String?
    public var unique3: String?
    public var groupId: String?
}

public struct AttributionIds: Codable {
    public var installId: String?
    public var clickId: String?
    public var userId: String?
}

public struct GoogleInstallReferrerData: Codable {
    public var gclid: String?
    public var gbraid: String?
    public var gadSource: String?
    public var wbraid: String?
}

public enum PostbackDecision: String, Codable {
    case passed
    case failed

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        guard let value = PostbackDecision(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid PostbackDecision: \(rawValue)")
        }
        self = value
    }
}
