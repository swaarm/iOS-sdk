@testable import SwaarmSdk
import XCTest

final class SwaarmSdkTests: XCTestCase {
    func testConfig() throws {
        SwaarmAnalytics.configure(token: "asdf", host: "google.com")
        SwaarmAnalytics.apiQueue.sync {}
        XCTAssert(SwaarmAnalytics.isInitialized)
        XCTAssert(SwaarmAnalytics.publisher!.configuredBreakpoints.count == 0)
        SwaarmAnalytics.setInitialized(initialized: false)
    }

    func testConfigAres() throws {
        SwaarmAnalytics.configure(
            token: "4e30d105720586e26f60e3c521b0792950f0c2fea0f55b64280b0f7b8f88e445", host: "https://track.ares.swaarm-clients.com"
        )
        SwaarmAnalytics.apiQueue.sync {}
        XCTAssert(SwaarmAnalytics.isInitialized)
        XCTAssert(SwaarmAnalytics.publisher!.configuredBreakpoints.count > 0)
        SwaarmAnalytics.setInitialized(initialized: false)
    }
}
