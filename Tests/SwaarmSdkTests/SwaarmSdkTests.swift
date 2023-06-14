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
            token: "skhuehkpe72c0aoafxz0nqrfutmiolwt5tlp4no65ly", host: "https://track.venus.swaarm-clients.com"
        )
        SwaarmAnalytics.apiQueue.sync {}
        XCTAssert(SwaarmAnalytics.isInitialized)
        XCTAssert(SwaarmAnalytics.publisher!.configuredBreakpoints.count > 0)
        SwaarmAnalytics.setInitialized(initialized: false)
    }
}
