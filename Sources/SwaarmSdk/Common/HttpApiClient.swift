import Foundation
import Gzip
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

    public func sendPostBlocking<T: Encodable>(requestUri: String, requestData: T) throws {
        let httpBody = try! (try JSONEncoder().encode(requestData)).gzipped()
        _ = try call(method: "POST", requestUri: requestUri, httpBody: httpBody)
    }

    public func getBlocking<T: Decodable>(requestUri: String, responseType: T.Type) throws -> T {
        return try JSONDecoder().decode(responseType, from: call(method: "GET", requestUri: requestUri)!)
    }

    public func call(method: String, requestUri: String, httpBody: Data? = nil) throws -> Data? {
        var request = URLRequest(url: URL(string: host + requestUri)!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue(ua, forHTTPHeaderField: "User-Agent")
        request.httpMethod = method
        if httpBody != nil {
            request.httpBody = httpBody
        }

        var responseData: Data?
        var internalError: Error?
        var internalResponse: URLResponse?

        let semaphore = DispatchSemaphore(value: 0)
        urlSession.dataTask(with: request) { data, response, error in
            if error != nil {
                internalError = error
            }  else {
                internalResponse = response
                if data != nil {
                    responseData = data
                }
            }
            semaphore.signal()
        }
        if internalError != nil {
            throw internalError!
        }

        _ = semaphore.wait(timeout: .now() + DispatchTimeInterval.seconds(10))

        Logger.debug(String(format: "API endpoint %@ returned response code %@", requestUri, String((internalResponse as! HTTPURLResponse).statusCode)))
        guard (200 ... 299) ~= (internalResponse as! HTTPURLResponse).statusCode else {
            os_log("Failed to send API SDK request the statusCode should be 2xx", type: .error)
            throw NSError(domain: "swaarm_sdk", code: 1, userInfo: ["response": internalResponse!, "request": request])
        }
        return responseData
    }
}
