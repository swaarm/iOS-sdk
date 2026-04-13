@testable import SwaarmSdk
import XCTest

final class SwaarmSdkTests: XCTestCase {
    func testConfig() async throws {
        await SwaarmAnalytics.configureAsync(token: "asdf", host: "google.com")
        XCTAssert(SwaarmAnalytics.isInitialized)
        XCTAssert(SwaarmAnalytics.publisher!.configuredBreakpoints.count == 0)
        SwaarmAnalytics.setInitialized(initialized: false)
    }

    func testConfigVenus() async throws {
        await SwaarmAnalytics.configureAsync(
            token: "skhuehkpe72c0aoafxz0nqrfutmiolwt5tlp4no65ly", host: "https://track.venus.swaarm-clients.com"
        )
        XCTAssert(SwaarmAnalytics.isInitialized)
        XCTAssert(SwaarmAnalytics.publisher!.configuredBreakpoints.count > 0)
        SwaarmAnalytics.setInitialized(initialized: false)
    }
}
