import Foundation
import os.log

class EventPublisher {

    private let repository: EventRepository
    private let workerQueue: DispatchQueue = DispatchQueue(label: "swaarm-event-publisher")
    private let allowedFailedAttempts = 30
    private var failedAttempts = 0;
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
            if self.shouldStop() == true {
                self.timer.cancel()
                Logger.debug("Terminating event publisher")
                return
            }

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
                   self.failedAttempts = 0
                },
                errorHandler: {
                   self.failedAttempts += 1
                }
            )
        }
        
        timer.resume()
    }
    
    public func stop() {
        timer.suspend()
    }
    
    private func shouldStop() -> Bool {
        return self.failedAttempts >= self.allowedFailedAttempts
    }

}
