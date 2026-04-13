import Foundation

class DeepLinkManager {
    private let httpApiClient: HttpApiClient
    private let callback: ((String) -> Void)?

    private static let firstRunKey = "SwaarmSdk.firstRun"

    init(httpApiClient: HttpApiClient, callback: ((String) -> Void)?) {
        self.httpApiClient = httpApiClient
        self.callback = callback
    }

    func checkForDeferredDeepLink() {
        guard let callback else { return }

        let isFirstRun = UserDefaults.standard.object(forKey: Self.firstRunKey) == nil
            || UserDefaults.standard.bool(forKey: Self.firstRunKey)

        guard isFirstRun else {
            Logger.debug("Not first run, skipping deferred deep link check")
            return
        }

        UserDefaults.standard.set(false, forKey: Self.firstRunKey)

        Task {
            do {
                let deepLink = try await httpApiClient.getString(requestUri: "/deeplink")
                Logger.debug("Received deferred deep link: \(deepLink)")
                callback(deepLink)
            } catch {
                Logger.debug("Deferred deep link fetch failed: \(error)")
            }
        }
    }
}
