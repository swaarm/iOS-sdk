import Foundation

public class TrackerState {
    var trackingEnabled: Bool = true
    let weqConfig: SwaarmConfig
    let sdkConfig: SdkConfiguration
    let session: Session
    
    init(config: SwaarmConfig, sdkConfig: SdkConfiguration, session: Session) {
        self.weqConfig = config;
        self.sdkConfig = sdkConfig
        self.session = session;
    }
    
    public func setTrackingEnabled(enabled : Bool) {
        trackingEnabled = enabled
    }
    
    public func isTrackingEnabled() -> Bool {
        trackingEnabled
    }
}
