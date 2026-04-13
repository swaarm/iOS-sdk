import AdSupport
import Foundation
import os.log
import Security
import UIKit

public typealias AttributionCallback = (AttributionData) -> Void
public typealias DeferredDeepLinkCallback = (String) -> Void

public class SwaarmAnalytics {
    private static var eventRepository: EventRepository?
    public static var publisher: EventPublisher?
    static var isInitialized: Bool = false
    private static var urlSession: URLSession = .shared
    private static var configureTask: Task<Void, Never>?
    private static var attributionManager: AttributionManager?
    private static var deepLinkManager: DeepLinkManager?

    public static var attributionData: AttributionData? {
        attributionManager?.attributionData
    }

    public static func configure(
        token: String,
        host: String,
        batchSize: Int = 50,
        flushFrequency: Int = 2,
        maxSize: Int = 500,
        debug: Bool = false,
        attributionCallback: AttributionCallback? = nil,
        deferredDeepLinkCallback: DeferredDeepLinkCallback? = nil
    ) {
        configureTask = Task {
            await configureAsync(
                token: token,
                host: host,
                batchSize: batchSize,
                flushFrequency: flushFrequency,
                maxSize: maxSize,
                debug: debug,
                attributionCallback: attributionCallback,
                deferredDeepLinkCallback: deferredDeepLinkCallback
            )
        }
    }

    public static func configureAsync(
        token: String,
        host: String,
        batchSize: Int = 50,
        flushFrequency: Int = 2,
        maxSize: Int = 500,
        debug: Bool = false,
        attributionCallback: AttributionCallback? = nil,
        deferredDeepLinkCallback: DeferredDeepLinkCallback? = nil
    ) async {
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

        guard let vendorId = await UIDevice.current.identifierForVendor?.uuidString else {
            Logger.debug("No vendorId found! stopping.")
            return
        }

        if let allowedVendors = try? await httpApiReader.get(
            requestUri: "/sdk-allowed-breakpoint-collectors",
            responseType: [String].self
        ) {
            Logger.debug("allowed vendors: \(allowedVendors)")
            if allowedVendors.contains(vendorId) {
                collect = true
            }
        }

        Logger.debug("collect is set to \(collect) for \(vendorId).")

        if let configuredBreakpointsData = try? await httpApiReader.get(
            requestUri: "/sdk-tracked-breakpoints",
            responseType: ConfiguredBreakpoints.self
        ) {
            configuredBreakpoints = Dictionary(configuredBreakpointsData.viewBreakpoints.map { ($0.viewName, $0.eventType) }, uniquingKeysWith: { _, last in last })
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

        // Attribution data fetching with exponential backoff
        self.attributionManager = AttributionManager(
            httpApiClient: httpApiReader,
            vendorId: vendorId,
            callback: attributionCallback
        )
        self.attributionManager?.start()

        // Deferred deep link check (first run only)
        self.deepLinkManager = DeepLinkManager(
            httpApiClient: httpApiReader,
            callback: deferredDeepLinkCallback
        )
        self.deepLinkManager?.checkForDeferredDeepLink()
    }

    public static func event(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "") {
        baseEvent(typeId: typeId, aggregatedValue: aggregatedValue, customValue: customValue)
    }

    public static func purchase(typeId: String? = nil, revenue: Double = 0.0, currency: String? = nil, receipt: String? = nil) {
        baseEvent(typeId: typeId, revenue: revenue, currency: currency, receipt: receipt)
    }

    static func baseEvent(typeId: String? = nil, aggregatedValue: Double = 0.0, customValue: String = "", revenue: Double = 0.0, currency: String? = nil, receipt: String? = nil) {
        if isInitialized == false {
            Logger.debug("Tracker is not initialized")
            return
        }

        eventRepository!.addEvent(typeId: typeId, aggregatedValue: aggregatedValue, customValue: customValue, revenue: revenue, currency: currency, receipt: receipt)
        Logger.debug("received event with typeId \(typeId as String?) aggregatedValue \(aggregatedValue) customValue \(customValue) revenue \(revenue) currency \(currency as String?) receipt \(receipt as String?)")
    }

    public static func disableTracking() {
        publisher?.stop()
        attributionManager?.stop()
        Logger.debug("Tracking disabled")
    }

    public static func enableTracking() {
        publisher?.start()
        attributionManager?.start()
        Logger.debug("Tracking resumed")
    }

    public static func debug(enable: Bool) {
        Logger.setIsEnabled(enabled: enable)
    }

    public static func setInitialized(initialized: Bool) {
        isInitialized = initialized
    }

    static func checkReinstall() -> Bool {
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
                kSecValueData: DateTime.now().data(using: .utf8)!,
            ] as NSDictionary, nil)
            guard statusCreate == errSecSuccess else { Logger.debug("Error writing to keychain! \(statusCreate)"); return false }
            return false
        default:
            Logger.debug("Error reading from keychain! \(status)")
            return false
        }
    }
}
