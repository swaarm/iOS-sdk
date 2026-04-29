import Foundation
#if canImport(AdServices)
import AdServices
#endif

/// Fetches Apple Search Ads attribution data on first launch.
///
/// Uses Apple's `AdServices` framework (iOS 14.3+) to obtain an attribution
/// token, then exchanges it with `https://api-adservices.apple.com/api/v1/`
/// for the actual campaign metadata. If the install was attributed to an
/// Apple Search Ads campaign, returns an `InstallReferrer` whose `referrer`
/// is a UTM-formatted string.
///
/// Returns `nil` when:
/// - Running on iOS < 14.3
/// - Token retrieval fails (user opted out of personalized ads, etc.)
/// - Apple's API does not attribute the install (`attribution: false`)
/// - Network/parse errors after the configured retry budget is exhausted
enum AppleAdsAttribution {
    private static let endpoint = URL(string: "https://api-adservices.apple.com/api/v1/")!
    private static let maxRetries = 3
    private static let retryDelaySeconds: UInt64 = 5

    static func fetchInstallReferrer() async -> InstallReferrer? {
        guard #available(iOS 14.3, *) else {
            Logger.debug("Apple Ads attribution requires iOS 14.3+, skipping")
            return nil
        }

        let token: String
        do {
            token = try AAAttribution.attributionToken()
        } catch {
            Logger.debug("Apple Ads: failed to get attribution token: \(error)")
            return nil
        }

        guard let response = await postToken(token) else {
            return nil
        }

        guard response.attribution == true else {
            Logger.debug("Apple Ads: install not attributed to a campaign")
            return nil
        }

        let utm = buildUtmString(from: response)
        let clickTimestamp = response.clickDate.flatMap(parseClickDate)

        Logger.debug("Apple Ads attributed install: \(utm)")
        return InstallReferrer(
            referrer: utm,
            clickTimestamp: clickTimestamp,
            installBeginTimestamp: nil
        )
    }

    private static func postToken(_ token: String) async -> AppleAdsResponse? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = token.data(using: .utf8)
        request.timeoutInterval = 10

        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await URLSession.shared.dataCompatApple(for: request)
                guard let http = response as? HTTPURLResponse else {
                    Logger.debug("Apple Ads: unexpected response type")
                    return nil
                }

                // Apple's endpoint returns 404 for ~10s after install — retry
                if http.statusCode == 404 && attempt < maxRetries {
                    Logger.debug("Apple Ads: 404 (attempt \(attempt)), retrying in \(retryDelaySeconds)s")
                    try? await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
                    continue
                }

                guard (200...299).contains(http.statusCode) else {
                    Logger.debug("Apple Ads: HTTP \(http.statusCode)")
                    return nil
                }

                return try JSONDecoder().decode(AppleAdsResponse.self, from: data)
            } catch {
                Logger.debug("Apple Ads: request failed (attempt \(attempt)): \(error)")
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
                }
            }
        }

        return nil
    }

    private static func buildUtmString(from response: AppleAdsResponse) -> String {
        var parts = ["utm_source=appleads"]
        if let id = response.campaignId { parts.append("utm_campaign=\(id)") }
        if let id = response.adGroupId  { parts.append("utm_adgroup=\(id)") }
        if let id = response.adId       { parts.append("utm_adid=\(id)") }
        if let id = response.keywordId  { parts.append("utm_keyword=\(id)") }
        return parts.joined(separator: "&")
    }

    private static func parseClickDate(_ raw: String) -> Int64? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: raw) {
            return Int64(date.timeIntervalSince1970)
        }
        // Fallback: Apple sometimes returns fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) {
            return Int64(date.timeIntervalSince1970)
        }
        return nil
    }
}

// MARK: - Apple's response shape

private struct AppleAdsResponse: Decodable {
    let attribution: Bool?
    let campaignId: Int?
    let adGroupId: Int?
    let adId: Int?
    let keywordId: Int?
    let clickDate: String?
}

// MARK: - URLSession iOS 14 compat

private extension URLSession {
    func dataCompatApple(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await data(for: request)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                dataTask(with: request) { data, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let data, let response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }.resume()
            }
        }
    }
}
