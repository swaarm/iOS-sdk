import Foundation
import os.log

class JsonEncoder {

    public static func encode<T: Encodable>(_ value: T) -> String? {
        let jsonEncoder = JSONEncoder()
        var json: String?
        do {
            let jsonData = try jsonEncoder.encode(value)
            json = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch {
            os_log("An error occurred while encoding data: '%@'", type: .error, String(describing: value))
        }

        return json;
    }

    public static func decode<T>(_ type: T.Type, from data: String) -> T? where T : Decodable {
        let jsonDecoder = JSONDecoder()
        let jsonData = data.data(using: .utf8)!
        var value: T?
        do {
            value = try jsonDecoder.decode(type, from: jsonData)
        } catch {
            os_log("An error occurred while decoding data: '%@'", type: .error, data)
        }
        return value
    }

}
