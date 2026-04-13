import Foundation
import UIKit

// eg. iPhone15,2
func deviceName() -> String {
    #if targetEnvironment(simulator)
    if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return simulatorModel
    }
    #endif
    var sysinfo = utsname()
    uname(&sysinfo)
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}

func UAString() -> String {
    let osv = UIDevice.current.systemVersion
    let model = deviceName()
    return "SwaarmSDK Os##iOS##;Osv##\(osv)##;Muf##Apple##;Model##\(model)##;"
}
