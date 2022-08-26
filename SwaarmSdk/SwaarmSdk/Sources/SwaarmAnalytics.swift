import AdSupport
import Foundation
import os.log
import UIKit
import WebKit

public enum SwaarmAnalytics {
    private static var eventRepository: EventRepository?
    private static var publisher: EventPublisher?
    private static var isInitialized: Bool = false
    private static var urlSession: URLSession = .shared
    private static var apiQueue: DispatchQueue = .init(label: "swaarm-api")

    public static func configure(config: SwaarmConfig? = nil, token: String? = nil, host: String? = nil,
                                 batchSize: Int = 50, flushFrequency: Int = 10, maxSize: Int = 500,
                                 debug: Bool = false)
    {
        if debug {
            self.debug(enable: debug)
        }
        let ua = WKWebView().value(forKey: "userAgent") as! String? ?? ""

        apiQueue.async {
            if self.isInitialized {
                Logger.debug("Already initialized.")
                return
            }

            var collect = false
            var configuredBreakpoints: [String: String] = [:]

            let httpApiReader = HttpApiClient(host: host ?? config!.eventIngressHostname, token: token ?? config!.appToken, urlSession: urlSession, ua: ua)
            guard let vendorId = UIDevice.current.identifierForVendor?.uuidString else {
                Logger.debug("No vendorId found! stopping.")
                return
            }
            httpApiReader.get(
                requestUri: "/sdk-allowed-breakpoint-collectors",
                successHandler: { (result: String) in
                    Logger.debug("received \(result)")
                    if (JsonEncoder.decode([String].self, from: result) ?? []).contains(vendorId) {
                        collect = true
                    }
                }, errorHandler: {}
            )

            httpApiReader.get(
                requestUri: "/sdk-tracked-breakpoints",
                successHandler: { (result: String) in
                    Logger.debug("received \(result)")
                    if let configuredBreakpointsData = JsonEncoder.decode(ConfiguredBreakpoints.self, from: result) {
                        configuredBreakpoints = Dictionary(uniqueKeysWithValues: configuredBreakpointsData.viewBreakpoints.map { ($0.viewName, $0.eventType) })
                    }
                }, errorHandler: {}
            )

            self.eventRepository = EventRepository(maxSize: maxSize, batchSize: batchSize, vendorId: vendorId)

            self.publisher = EventPublisher(
                repository: eventRepository!,
                httpApiReader: httpApiReader,
                flushFrequency: flushFrequency,
                collect: collect,
                configuredBreakpoints: configuredBreakpoints
            )
            self.publisher!.start()

            self.isInitialized = true
            if !(UserDefaults.standard.object(forKey: "SwaarmSdk.initEventSent") as? Bool ?? false) {
                SwaarmAnalytics.event()
                UserDefaults.standard.set(true, forKey: "SwaarmSdk.initEventSent")
            }
            SwaarmAnalytics.event(typeId: "__open")
        }
    }

    public static func event(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "", revenue: Double = 0.0) {
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
        publisher!.stop()
        Logger.debug("Tracking disabled")
    }

    public static func enableTracking() {
        publisher!.start()
        Logger.debug("Tracking resumed")
    }

    public static func debug(enable: Bool) {
        Logger.setIsEnabled(enabled: enable)
    }

    public static func setInitialized(initialized: Bool) {
        isInitialized = initialized
    }
}
