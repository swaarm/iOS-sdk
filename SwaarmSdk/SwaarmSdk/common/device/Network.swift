import Foundation
import CoreTelephony

public enum Network: String {
    case wifi = "en0"
    case cellular = "pdp_ip0"
}

public enum ConnectionType: String, Codable {
    case WIFI
    case CELLULAR_2_G
    case CELLULAR_3_G
    case CELLULAR_4_G
    case CELLULAR_5_G
    case UNKNOWN;
}

public class UtilNetwork {

    public static func isConnected() -> Bool {
        UtilNetwork.getNetworkType() != ConnectionType.UNKNOWN
    }
    
    public static func findAddress() -> String {
        let wifiIp = UtilNetwork.getAddress(for: .wifi) ?? ""
        let cellularIp = UtilNetwork.getAddress(for: .cellular) ?? ""
        return (!cellularIp.isEmpty) ? cellularIp : wifiIp
    }

    public static func getAddress(for network: Network) -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == network.rawValue {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }

    public static func getNetworkType() -> ConnectionType {
        var reachability: Reachability
        do {
            reachability = try Reachability()
        } catch {
            return ConnectionType.UNKNOWN
        }
        do {
            try reachability.startNotifier()
            switch reachability.connection {
            case .unavailable:     return ConnectionType.UNKNOWN
            case .wifi: return ConnectionType.WIFI
            case .cellular: return UtilNetwork.getWWANNetworkType()
            case .none: return ConnectionType.UNKNOWN
            }
        } catch {
            return ConnectionType.UNKNOWN
        }
    }

    static func getWWANNetworkType() -> ConnectionType {
        guard let currentRadioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology else {
            return ConnectionType.UNKNOWN
        }
        switch currentRadioAccessTechnology {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return ConnectionType.CELLULAR_2_G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return ConnectionType.CELLULAR_3_G
        case CTRadioAccessTechnologyLTE:
            return ConnectionType.CELLULAR_4_G
        default:
            return ConnectionType.UNKNOWN
        }
    }
}
