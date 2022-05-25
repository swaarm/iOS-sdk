import Foundation
import SQLite3
import os.log
import AdSupport
import CoreTelephony
import UIKit

class EventRepository {
    private let sdkConfig: SdkConfiguration
    private let trackerState: TrackerState
    private var eventsStore = [String : TrackingEvent]()
    
    init(trackerState: TrackerState) {
        self.trackerState = trackerState
        self.sdkConfig = trackerState.sdkConfig
    }

    public func addEvent(typeId: String?, aggregatedValue: Double, customValue: String) {

      let device = UIDevice.current

       let trackingEvent = TrackingEvent(
            id: UUID().uuidString,
            typeId: typeId,
            aggregatedValue: aggregatedValue,
            customValue: customValue,
            vendorId: device.identifierForVendor?.uuidString ?? "",
            clientTime: DateTime.now(),
            osv: device.systemVersion
        )
            
        self.eventsStore[trackingEvent.id] = trackingEvent
    }

    public func getEvents(limit: Int) -> [TrackingEvent] {
        var events: [TrackingEvent] = []
        var counter: Int = 0
        eventsStore.forEach { (eventId: String, event: TrackingEvent) in
            if (counter < limit) {
               events.append(event)
            }
            counter+=1
        }
        
        return events
    }

    public func clearByEvents(events: [TrackingEvent]) {
        events.forEach { event in
            eventsStore.removeValue(forKey: event.id)
        }
    }
}
