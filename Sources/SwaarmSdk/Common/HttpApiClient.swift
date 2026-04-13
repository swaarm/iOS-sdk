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

    public func sendPost<T: Encodable>(requestUri: String, requestData: T) async throws {
        let httpBody = try JSONEncoder().encode(requestData).gzipped()
        _ = try await call(method: "POST", requestUri: requestUri, httpBody: httpBody)
    }

    public func get<T: Decodable>(requestUri: String, queryParams: [String: String]? = nil, responseType: T.Type) async throws -> T {
        let uri = buildUri(requestUri: requestUri, queryParams: queryParams)
        guard let data = try await call(method: "GET", requestUri: uri) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(responseType, from: data)
    }

    public func getString(requestUri: String, queryParams: [String: String]? = nil) async throws -> String {
        let uri = buildUri(requestUri: requestUri, queryParams: queryParams)
        guard let data = try await call(method: "GET", requestUri: uri) else {
            throw URLError(.badServerResponse)
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return string
    }

    private func buildUri(requestUri: String, queryParams: [String: String]?) -> String {
        guard let queryParams, !queryParams.isEmpty else { return requestUri }
        let query = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return "\(requestUri)?\(query)"
    }

    public func call(method: String, requestUri: String, httpBody: Data? = nil) async throws -> Data? {
        guard let url = URL(string: host + requestUri) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue(ua, forHTTPHeaderField: "User-Agent")
        request.httpMethod = method
        request.timeoutInterval = 10

        if let httpBody {
            request.httpBody = httpBody
        }

        let (data, response) = try await urlSession.dataCompat(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        Logger.debug(String(format: "API endpoint %@ returned response code %@", requestUri, String(httpResponse.statusCode)))

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}

private extension URLSession {
    func dataCompat(for request: URLRequest) async throws -> (Data, URLResponse) {
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
