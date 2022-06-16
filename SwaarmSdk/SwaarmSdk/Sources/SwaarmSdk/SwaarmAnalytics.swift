import Foundation
import UIKit
import AdSupport
import os.log
import WebKit

public class SwaarmAnalytics {
    
    private static var eventRepository: EventRepository?
    private static var trackerState: TrackerState?
    private static var isInitialized: Bool = false
    private static var urlSession: URLSession = URLSession.shared
    private static var apiQueue: DispatchQueue = DispatchQueue(label: "swaarm-api");
    
    public static func configure(config: SwaarmConfig) {
        self.configure(config: config, sdkConfig: SdkConfiguration())
    }
    
    public static func configure(config: SwaarmConfig, sdkConfig: SdkConfiguration) {
        if !config.isAppTokenValid() {
            Logger.debug("App token is not set")
            return;
        }
        let ua = WKWebView().value(forKey: "userAgent") as! String? ?? ""
        
        apiQueue.async(execute: {
            if (self.isInitialized) {
                Logger.debug("Already initialized.")
                return;
            }
            
            self.trackerState = TrackerState(config: config, sdkConfig: sdkConfig, session: Session())

            let httpApiReader = HttpApiClient(trackerState: self.trackerState!, urlSession: urlSession, ua: ua)

            self.eventRepository = EventRepository(trackerState: self.trackerState!)
            
            EventPublisher(
                repository: eventRepository!,
                trackerState: self.trackerState!,
                httpApiReader: httpApiReader
            ).start()
            
            self.isInitialized = true;
             

            if UserDefaults.standard.object(forKey: "firstStart") as? Bool ?? false {
                SwaarmAnalytics.event(typeId: nil, aggregatedValue: 0.0)
            } else {
                UserDefaults.standard.set(true, forKey: "firstStart")
            }
            })
    }
    
    public static func event(typeId: String?, aggregatedValue: Double, customValue: String) {
        guard let state = self.trackerState else {
            Logger.debug("Tracker state is not initialized")
            return
        }
        
        if !state.isTrackingEnabled() {
            return
        }
        
        if (self.isInitialized == false) {
            Logger.debug("Tracker is not initialized")
            return
        }
    
        
        eventRepository!.addEvent(typeId: typeId, aggregatedValue: aggregatedValue, customValue: customValue)
    }
    
    public static func configure(appToken: String, eventIngressHostname: String) {
        self.configure(config: SwaarmConfig(appToken: appToken, eventIngressHostname: eventIngressHostname))
    }
    
    public static func event(typeId: String?, aggregatedValue: Double) {
        
        self.event(typeId: typeId, aggregatedValue: aggregatedValue, customValue: "")
    }
    
    public static func disableTracking() {
        guard let state = self.trackerState else {
            Logger.debug("Tracker not initialized.")
            return
        }
        
        state.setTrackingEnabled(enabled: false)
        Logger.debug("Tracking disabled")
    }
    
    public static func enableTracking() {
        guard let state = self.trackerState else {
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
        self.isInitialized = initialized
    }
}
