import Foundation
import os.log

class EventPublisher {

    private let repository: EventRepository
    private let workerQueue: DispatchQueue = DispatchQueue(label: "swaarm-event-publisher")
    private let trackerState: TrackerState
    private let allowedFailedAttempts = 30
    private var failedAttempts = 0;
    private var startupDelayInSeconds = 10
    private var timer: DispatchSourceTimer
    private var httpApiReader: HttpApiClient

    init(repository: EventRepository, trackerState: TrackerState, httpApiReader: HttpApiClient) {
        self.repository = repository
        self.trackerState = trackerState;
        self.timer = DispatchSource.makeTimerSource(queue: workerQueue)
        self.httpApiReader = httpApiReader
        
        timer.schedule(
            deadline: .now() + DispatchTimeInterval.seconds(startupDelayInSeconds),
            repeating: DispatchTimeInterval.seconds(trackerState.sdkConfig.getEventFlushFrequencyInSeconds())
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
            
            if self.shouldSkip() == true {
                return
            }
            
            let events = self.repository.getEvents(limit: self.trackerState.sdkConfig.getEventFlushBatchSize())
            if events.count == 0 {
                return
            }

            let trackingEventBatch = self.createTrackingEventBatch(events)
            guard let jsonRequest = JsonEncoder.encode(trackingEventBatch) else {
                Logger.debug("Unable to decode event data, skipping")
                return
            }

            Logger.debug(String(format:"Sending batch of '%d' events", events.count))
            
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
    
    private func createTrackingEventBatch(_ events: [TrackingEvent]) -> TrackingEventBatch {
        return TrackingEventBatch(events: events, time: DateTime.now())
    }
    
    private func shouldStop() -> Bool {
        return self.failedAttempts >= self.allowedFailedAttempts
    }
    
    private func shouldSkip() -> Bool {
        if !self.trackerState.isTrackingEnabled() {
            return true
        }
        
        if !UtilNetwork.isConnected() {
            return true
        }
        
        return false
    }
}
