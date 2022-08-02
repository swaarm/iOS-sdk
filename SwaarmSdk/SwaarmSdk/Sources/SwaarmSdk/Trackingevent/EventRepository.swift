import AdSupport
import CoreTelephony
import Foundation
import os.log
import SQLite3
import UIKit

class EventRepository {
    private let sdkConfig: SdkConfiguration
    private let trackerState: TrackerState
    private var eventsStore: OrderedDictionary<String, TrackingEvent> = [:]

    init(trackerState: TrackerState) {
        self.trackerState = trackerState
        sdkConfig = trackerState.sdkConfig
    }

    public func addEvent(typeId: String?, aggregatedValue: Double, customValue: String, revenue: Double) {
        let device = UIDevice.current

        let trackingEvent = TrackingEvent(
            id: UUID().uuidString,
            typeId: typeId,
            aggregatedValue: aggregatedValue,
            customValue: customValue,
            revenue: revenue,
            vendorId: device.identifierForVendor?.uuidString ?? "",
            clientTime: DateTime.now(),
            osv: device.systemVersion
        )

        if eventsStore.count >= trackerState.sdkConfig.getEventStorageSizeLimit() {
            eventsStore.removeFirst()
        }

        eventsStore[trackingEvent.id] = trackingEvent
    }

    public func getEvents(limit: Int) -> [TrackingEvent] {
        var events: [TrackingEvent] = []
        var counter = 0

        for event in eventsStore.values {
            if counter < limit {
                events.append(event)
            }
            counter += 1
        }

        return events
    }

    public func clearByEvents(events: [TrackingEvent]) {
        if eventsStore.count == 0 {
            return
        }

        for event in events {
            eventsStore.removeValue(forKey: event.id)
        }
    }
}
