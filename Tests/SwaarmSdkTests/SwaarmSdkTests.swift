@testable import SwaarmSdk
import XCTest

final class SwaarmSdkTests: XCTestCase {
    func testEmptyNotWorking() throws {
        SwaarmAnalytics.configure()
        while(!SwaarmAnalytics.initialized) {

        }
        SwaarmAnalytics.setInitialized(initialized: false)
    }

    func testConfig() throws {
        SwaarmAnalytics.configure(config: SwaarmConfig(appToken: "asdf", eventIngressHostname: "google.com"))
        SwaarmAnalytics.setInitialized(initialized: false)
    }

    func testSimpleConfig() throws {
        SwaarmAnalytics.configure(token: "asdf", host: "google.com")
        SwaarmAnalytics.setInitialized(initialized: false)
    }
}
