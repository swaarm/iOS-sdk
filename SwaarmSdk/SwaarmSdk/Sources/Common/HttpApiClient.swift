import Foundation
import os.log

public class HttpApiClient {
    private let urlSession: URLSession
    private let ua: String
    private let token: String
    private let host: String

    init(host: String, token: String, urlSession: URLSession = .shared, ua: String) {
        self.urlSession = urlSession
        self.ua = ua
        self.host = host
        self.token = token
    }

    public func sendPostBlocking(jsonRequest: String, requestUri: String, successHandler: @escaping (String) -> Void, errorHandler: @escaping () -> Void) {
        callBlocking(method: "POST", jsonRequest: jsonRequest, requestUri: requestUri, successHandler: successHandler, errorHandler: errorHandler)
    }

    public func getBlocking(requestUri: String, successHandler: @escaping (String) -> Void, errorHandler _: @escaping () -> Void) {
        callBlocking(method: "GET", jsonRequest: nil, requestUri: requestUri, successHandler: successHandler, errorHandler: {})
    }

    public func callBlocking(method: String, jsonRequest: String?, requestUri: String, successHandler: @escaping (String) -> Void, errorHandler: @escaping () -> Void) {
        let semaphore = DispatchSemaphore(value: 0)

        let semaphoreAwareSuccessHandler: (String) -> Void = { jsonResponse in
            successHandler(jsonResponse)
            semaphore.signal()
        }

        let semaphoreAwareErrorHandler = {
            errorHandler()
            semaphore.signal()
        }
        call(method: method, jsonRequest: jsonRequest, requestUri: requestUri, successHandler: semaphoreAwareSuccessHandler, errorHandler: semaphoreAwareErrorHandler)
        _ = semaphore.wait(timeout: .now() + DispatchTimeInterval.seconds(10))
    }

    public func call(method: String, jsonRequest: String?, requestUri: String, successHandler: @escaping (String) -> Void, errorHandler: @escaping () -> Void) {
        var request = URLRequest(url: URL(string: host + requestUri)!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue(ua, forHTTPHeaderField: "User-Agent")
        request.httpMethod = method
        if jsonRequest != nil {
            request.httpBody = try! (jsonRequest!.data(using: String.Encoding.utf8)?.gzipped())!
        }

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
