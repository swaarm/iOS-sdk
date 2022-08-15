import Foundation
import os.log

class EventPublisher {
    private let repository: EventRepository
    private let workerQueue: DispatchQueue = .init(label: "swaarm-event-publisher")
    private var startupDelayInSeconds = 10
    private var timer: DispatchSourceTimer
    private var httpApiReader: HttpApiClient
    private var breakpoints: Set<String> = []
    private var breakpoint: String = ""

    init(repository: EventRepository, httpApiReader: HttpApiClient, flushFrequency: Int) {
        self.repository = repository
        timer = DispatchSource.makeTimerSource(queue: workerQueue)
        self.httpApiReader = httpApiReader

        timer.schedule(
            deadline: .now() + DispatchTimeInterval.seconds(startupDelayInSeconds),
            repeating: DispatchTimeInterval.seconds(flushFrequency)
        )
    }

    public func recScan(controller: UIViewController) {
        for c in controller.children {
            recScan(controller: c)
        }
        let cname = String(describing: controller)
        if controller.isBeingPresented {
            breakpoint = cname
        }
        breakpoints.insert(cname)
    }

    public func start() {
        Logger.debug("Event publisher started")
        timer.setEventHandler {
            var window: UIWindow?
            DispatchQueue.main.async {
                if #available(iOS 13, *) {
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScene = scenes.first as? UIWindowScene
                    window = windowScene?.windows.first
                } else {
                    window = UIApplication.shared.keyWindow
                }
                recScan(controller: window!.rootViewController!)
            }
            Logger.debug("\(self.breakpoint) active. total breakpoints: \(self.breakpoints)")

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
                successHandler: { _ in
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
