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

    public func addEvent(typeId: String?, aggregatedValue: Double, customValue: String, revenue: Double) {

        let trackingEvent = TrackingEvent(
            id: UUID().uuidString,
            typeId: typeId,
            aggregatedValue: aggregatedValue,
            customValue: customValue,
            revenue: revenue,
            vendorId: vendorId,
            clientTime: DateTime.now(),
            osv: UIDevice.current.systemVersion
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
