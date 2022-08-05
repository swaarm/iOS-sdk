import Foundation
import os.log

class EventPublisher {

    private let repository: EventRepository
    private let workerQueue: DispatchQueue = DispatchQueue(label: "swaarm-event-publisher")
    private var startupDelayInSeconds = 10
    private var timer: DispatchSourceTimer
    private var httpApiReader: HttpApiClient

    init(repository: EventRepository, httpApiReader: HttpApiClient, flushFrequency: Int) {
        self.repository = repository
        self.timer = DispatchSource.makeTimerSource(queue: workerQueue)
        self.httpApiReader = httpApiReader
        
        timer.schedule(
            deadline: .now() + DispatchTimeInterval.seconds(startupDelayInSeconds),
            repeating: DispatchTimeInterval.seconds(flushFrequency)
        )
    }

    public func start() {
        Logger.debug("Event publisher started")
        timer.setEventHandler {

            let events = self.repository.getEvents()

            if events.count == 0 {
                return
            }

            guard let jsonRequest = JsonEncoder.encode(TrackingEventBatch(events: events, time: DateTime.now())) else {
                Logger.debug("Unable to decode event data, skipping")
                return
            }

            Logger.debug("Sending events \(jsonRequest)")
            
            self.httpApiReader.sendPostBlocking(
                jsonRequest: jsonRequest,
                requestUri: "/sdk",
                successHandler: { response in
                   Logger.debug("Event batch request successfully sent.")
                   self.repository.clearByEvents(events: events)
                }, errorHandler: {}
            )
        }
        
        timer.resume()
    }
    
    public func stop() {
        timer.suspend()
    }
}
