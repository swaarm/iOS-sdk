import AdSupport
import Foundation
import os.log
import UIKit
import WebKit

public class SwaarmAnalytics {
    private static var eventRepository: EventRepository?
    private static var trackerState: TrackerState?
    private static var isInitialized: Bool = false
    private static var urlSession: URLSession = .shared
    private static var apiQueue: DispatchQueue = .init(label: "swaarm-api")

    public static func configure(config: SwaarmConfig, debug: Bool = false) {
       let sdkConfig = SdkConfiguration()
        if debug {
            self.debug(enable: debug)
        }
        if !config.isAppTokenValid() {
            Logger.debug("App token is not set")
            return
        }
        let ua = WKWebView().value(forKey: "userAgent") as! String? ?? ""

        apiQueue.async {
            if self.isInitialized {
                Logger.debug("Already initialized.")
                return
            }

            self.trackerState = TrackerState(config: config, sdkConfig: sdkConfig, session: Session())

            let httpApiReader = HttpApiClient(trackerState: self.trackerState!, urlSession: urlSession, ua: ua)

            self.eventRepository = EventRepository(trackerState: self.trackerState!)

            EventPublisher(
                repository: eventRepository!,
                trackerState: self.trackerState!,
                httpApiReader: httpApiReader
            ).start()

            self.isInitialized = true

            if UserDefaults.standard.object(forKey: "firstStart") as? Bool ?? false {
                SwaarmAnalytics.event()
            } else {
                UserDefaults.standard.set(true, forKey: "firstStart")
            }
            SwaarmAnalytics.event(typeId: "__open")
        }
    }

    public static func event(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "", revenue: Double = 0.0) {
        guard let state = trackerState else {
            Logger.debug("Tracker state is not initialized")
            return
        }

        if !state.isTrackingEnabled() {
            return
        }

        if isInitialized == false {
            Logger.debug("Tracker is not initialized")
            return
        }

        eventRepository!.addEvent(typeId: typeId, aggregatedValue: aggregatedValue, customValue: customValue, revenue: revenue)
        Logger.debug("received event with typeId \(typeId as String?) aggregatedValue \(aggregatedValue) customValue \(customValue) revenue \(revenue)")
    }

    public static func configure(appToken: String, eventIngressHostname: String) {
        configure(config: SwaarmConfig(appToken: appToken, eventIngressHostname: eventIngressHostname))
    }

    public static func disableTracking() {
        guard let state = trackerState else {
            Logger.debug("Tracker not initialized.")
            return
        }

        state.setTrackingEnabled(enabled: false)
        Logger.debug("Tracking disabled")
    }

    public static func enableTracking() {
        guard let state = trackerState else {
            Logger.debug("Tracker not initialized.")
            return
        }

        state.setTrackingEnabled(enabled: true)
        Logger.debug("Tracking resumed")
    }

    public static func debug(enable: Bool) {
        Logger.setIsEnabled(enabled: enable)
    }

    public static func setInitialized(initialized: Bool) {
        isInitialized = initialized
    }
}
