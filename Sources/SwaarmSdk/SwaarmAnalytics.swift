import AdSupport
import Foundation
import os.log
import Security
import UIKit
import WebKit

@objc(SwaarmAnalytics)
public class SwaarmAnalytics: NSObject {
    private static var eventRepository: EventRepository?
    public static var publisher: EventPublisher?
    static var isInitialized: Bool = false
    private static var urlSession: URLSession = .shared
    static var apiQueue: DispatchQueue = .init(label: "swaarm-api", qos: .utility)

    @objc public static func configure(token: String, host: String, batchSize: Int = 50, flushFrequency: Int = 10, maxSize: Int = 500, debug: Bool = false)
    {
        apiQueue.async {
            if debug {
                self.debug(enable: debug)
            }
            let ua = UAString()

            if self.isInitialized {
                Logger.debug("Already initialized.")
                return
            }

            var collect = false
            var configuredBreakpoints: [String: String] = [:]

            var saneHost = host
            if saneHost.hasSuffix("/") {
                saneHost = String(saneHost.dropLast(1))
            }
            if saneHost.hasPrefix("http://") {
                saneHost = String(saneHost.dropFirst(7))
            }
            if !saneHost.hasPrefix("https://") {
                saneHost = "https://" + saneHost
            }

            let httpApiReader = HttpApiClient(host: saneHost, token: token, urlSession: urlSession, ua: ua)
            guard let vendorId = UIDevice.current.identifierForVendor?.uuidString else {
                Logger.debug("No vendorId found! stopping.")
                return
            }

            if let allowedVendors = try? httpApiReader.getBlocking(
                requestUri: "/sdk-allowed-breakpoint-collectors",
                responseType: [String].self
            ) {
                if allowedVendors.contains(vendorId) {
                    collect = true
                }
            }

            Logger.debug("collect is set to \(collect).")

            if let configuredBreakpointsData = try? httpApiReader.getBlocking(
                requestUri: "/sdk-tracked-breakpoints",
                responseType: ConfiguredBreakpoints.self
            ) {
                configuredBreakpoints = Dictionary(uniqueKeysWithValues: configuredBreakpointsData.viewBreakpoints.map { ($0.viewName, $0.eventType) })
            }

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
                if checkReinstall() {
                    SwaarmAnalytics.event(typeId: "__reinstall")
                } else {
                    SwaarmAnalytics.event()
                }
                UserDefaults.standard.set(true, forKey: "SwaarmSdk.initEventSent")
            }
            SwaarmAnalytics.event(typeId: "__open")
        }
    }

    @objc public static func event(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "", revenue: Double = 0.0) {
        if isInitialized == false {
            Logger.debug("Tracker is not initialized")
            return
        }

        eventRepository!.addEvent(typeId: typeId, aggregatedValue: aggregatedValue, customValue: customValue, revenue: revenue)
        Logger.debug("received event with typeId \(typeId as String?) aggregatedValue \(aggregatedValue) customValue \(customValue) revenue \(revenue)")
    }

    @objc public static func disableTracking() {
        publisher!.stop()
        Logger.debug("Tracking disabled")
    }

    @objc public static func enableTracking() {
        publisher!.start()
        Logger.debug("Tracking resumed")
    }

    @objc public static func debug(enable: Bool) {
        Logger.setIsEnabled(enabled: enable)
    }

    public static func setInitialized(initialized: Bool) {
        isInitialized = initialized
    }

    static func checkReinstall() -> Bool {
        // keychain survives uninstall. we only check for presence of the value.
        // bundleid is required, as depending on configuration of access groups, information may be shared between apps
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Bundle.main.bundleIdentifier as Any,
            kSecAttrService: "swaarm_attrib",
            kSecReturnData: false,
        ] as NSDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            let statusCreate = SecItemAdd([
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: Bundle.main.bundleIdentifier as Any,
                kSecAttrService: "swaarm_attrib",
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
                kSecValueData: DateTime.now().data(using: .utf8),
            ] as NSDictionary, nil)
            guard status == errSecSuccess else { Logger.debug("Error writing to keychain! \(statusCreate)"); return false }
            return false
        default:
            Logger.debug("Error reading from keychain! \(status)")
            return false
        }
    }
}
