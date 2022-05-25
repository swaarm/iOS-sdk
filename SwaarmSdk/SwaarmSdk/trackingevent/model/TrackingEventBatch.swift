import Foundation

class TrackingEventBatch: Codable {
    var events: Array<TrackingEvent>
    var time: String

    init(events: Array<TrackingEvent>, time: String) {
        self.events = events;
        self.time = time;
    }
}
