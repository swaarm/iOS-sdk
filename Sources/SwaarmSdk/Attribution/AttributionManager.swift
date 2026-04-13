import Foundation

class AttributionManager {
    private let httpApiClient: HttpApiClient
    private let vendorId: String
    private let callback: ((AttributionData) -> Void)?
    private var fetchTask: Task<Void, Never>?

    private(set) var attributionData: AttributionData?

    private static let cacheKey = "SwaarmSdk.attributionData"
    private let initialIntervalSeconds: Double = 2.0
    private let backoffExponent: Double = 1.5

    init(httpApiClient: HttpApiClient, vendorId: String, callback: ((AttributionData) -> Void)?) {
        self.httpApiClient = httpApiClient
        self.vendorId = vendorId
        self.callback = callback
        loadCachedData()
    }

    func start() {
        fetchTask = Task { [weak self] in
            guard let self else { return }
            var interval = self.initialIntervalSeconds

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                guard !Task.isCancelled else { break }

                do {
                    let data = try await self.httpApiClient.get(
                        requestUri: "/attribution-data",
                        queryParams: ["vendorId": self.vendorId],
                        responseType: AttributionData.self
                    )
                    self.attributionData = data
                    self.cacheData(data)

                    if data.decision != nil {
                        Logger.debug("Attribution data received with decision: \(data.decision!)")
                        if let callback = self.callback {
                            Logger.debug("Calling attribution callback")
                            callback(data)
                        }
                        break
                    }
                } catch {
                    Logger.debug("Attribution fetch failed: \(error)")
                }

                interval = pow(interval, self.backoffExponent)
                Logger.debug("Attribution backoff interval: \(interval)s")
            }
        }
    }

    func stop() {
        fetchTask?.cancel()
        fetchTask = nil
    }

    private func loadCachedData() {
        guard let jsonString = UserDefaults.standard.string(forKey: Self.cacheKey),
              let jsonData = jsonString.data(using: .utf8) else { return }
        do {
            attributionData = try JSONDecoder().decode(AttributionData.self, from: jsonData)
            Logger.debug("Loaded cached attribution data")
        } catch {
            Logger.debug("Failed to decode cached attribution data: \(error)")
        }
    }

    private func cacheData(_ data: AttributionData) {
        do {
            let jsonData = try JSONEncoder().encode(data)
            let jsonString = String(data: jsonData, encoding: .utf8)
            UserDefaults.standard.set(jsonString, forKey: Self.cacheKey)
        } catch {
            Logger.debug("Failed to cache attribution data: \(error)")
        }
    }
}
