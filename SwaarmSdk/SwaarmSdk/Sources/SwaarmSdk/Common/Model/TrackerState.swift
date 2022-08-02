import Foundation

public class TrackerState {
    var trackingEnabled: Bool = true
    let config: SwaarmConfig
    let sdkConfig: SdkConfiguration
    let session: Session

    init(config: SwaarmConfig, sdkConfig: SdkConfiguration, session: Session) {
        self.config = config
        self.sdkConfig = sdkConfig
        self.session = session
    }

    public func setTrackingEnabled(enabled: Bool) {
        trackingEnabled = enabled
    }

    public func isTrackingEnabled() -> Bool {
        trackingEnabled
    }
}
