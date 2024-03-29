import AdSupport
import CoreTelephony
import Foundation
import os.log
import SQLite3
import UIKit

class EventRepository {
    private var eventsStore: [TrackingEvent] = []
    private var maxSize: Int
    private var batchSize: Int
    private var vendorId: String

    init(maxSize: Int, batchSize: Int, vendorId: String) {
        self.maxSize = maxSize
        self.batchSize = batchSize
        self.vendorId = vendorId
    }

    public func addEvent(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "", revenue: Double = 0.0, currency: String? = nil, receipt: String? = nil) {
        var idfa: String? = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if idfa == "00000000-0000-0000-0000-000000000000" {
            idfa = nil
        }
        var iosPurchaseValidation: IosPurchaseValidation?
        if receipt != nil {
            iosPurchaseValidation = IosPurchaseValidation(receipt: receipt!)
        }
        Logger.debug("idfa: \(idfa as String?)")

        let trackingEvent = TrackingEvent(
            id: UUID().uuidString,
            typeId: typeId,
            aggregatedValue: aggregatedValue,
            customValue: customValue,
            revenue: revenue,
            vendorId: vendorId,
            clientTime: DateTime.now(),
            osv: UIDevice.current.systemVersion,
            advertisingId: idfa,
            currency: currency,
            iosPurchaseValidation: iosPurchaseValidation
        )

        while eventsStore.count >= maxSize {
            eventsStore.removeFirst()
        }

        eventsStore.append(trackingEvent)
    }

    public func getEvents() -> [TrackingEvent] {
        return Array(eventsStore[...(min(eventsStore.count, batchSize) - 1)])
    }

    public func clearByEvents(events: [TrackingEvent]) {
        if eventsStore.count == 0 {
            return
        }
        let eventIds = events.map { $0.id }
        eventsStore.removeAll(where: { eventIds.contains($0.id) })
    }
}
