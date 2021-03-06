import Foundation
import os.log

public class HttpApiClient {
    private let trackerState: TrackerState
    private let urlSession: URLSession
    private let ua: String

    init(trackerState: TrackerState, urlSession: URLSession = .shared, ua: String) {
        self.trackerState = trackerState
        self.urlSession = urlSession
        self.ua = ua
    }

    public func sendPostBlocking(jsonRequest: String, requestUri: String, successHandler: @escaping (String) -> Void, errorHandler: @escaping () -> Void) {
        let semaphore = DispatchSemaphore(value: 0)

        let semaphoreAwareSuccessHandler: (String) -> Void = { jsonResponse in
            successHandler(jsonResponse)
            semaphore.signal()
        }

        let semaphoreAwareErrorHandler = {
            errorHandler()
            semaphore.signal()
        }

        sendPost(jsonRequest: jsonRequest, requestUri: requestUri, successHandler: semaphoreAwareSuccessHandler, errorHandler: semaphoreAwareErrorHandler)

        _ = semaphore.wait(timeout: .now() + DispatchTimeInterval.seconds(10))
    }

    public func sendPost(jsonRequest: String, requestUri: String, successHandler: @escaping (String) -> Void) {
        sendPost(jsonRequest: jsonRequest, requestUri: requestUri, successHandler: successHandler, errorHandler: {})
    }

    public func sendPost(jsonRequest: String, requestUri: String, successHandler: @escaping (String) -> Void, errorHandler: @escaping () -> Void) {
        var request = URLRequest(url: URL(string: trackerState.config.eventIngressHostname + requestUri)!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        request.setValue("Bearer " + trackerState.config.appToken, forHTTPHeaderField: "Authorization")
        request.setValue(ua, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = try! (jsonRequest.data(using: String.Encoding.utf8)?.gzipped())!

        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let _ = data, let response = response as? HTTPURLResponse, error == nil else {
                os_log("An error occurred while sending SDK API request", type: .error, error as CVarArg? ?? "Unknown error")
                errorHandler()
                return
            }

            Logger.debug(String(format: "API endpoint %@ returned response code %@", requestUri, String(response.statusCode)))

            guard (200 ... 299) ~= response.statusCode else {
                os_log("Failed to send API SDK request the statusCode should be 2xx", type: .error)
                errorHandler()
                return
            }

            if let data = data {
                guard let jsonResponse = String(data: data, encoding: .utf8) else {
                    errorHandler()
                    return
                }

                successHandler(jsonResponse)
            }
        }

        task.resume()
    }
}
