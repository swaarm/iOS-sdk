import Foundation

public class TrackingEvent: Codable {
    var id: String
    var typeId: String?
    var aggregatedValue: Double
    var customValue: String
    var vendorId: String
    var clientTime: String
    var osv: String

    init(id: String, typeId: String?, aggregatedValue: Double, customValue: String, vendorId: String, clientTime: String, osv: String) {
        self.id = id
        self.typeId = typeId
        self.aggregatedValue = aggregatedValue
        self.customValue = customValue
        self.vendorId = vendorId
        self.clientTime = clientTime
        self.osv = osv
    }
}
