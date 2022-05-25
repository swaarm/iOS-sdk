import Foundation

public class SdkConfiguration {
    
    private let applicationConfig: NSDictionary
    
    init(applicationConfig: NSDictionary) {
        self.applicationConfig = applicationConfig
    }
    
    init() {
        let path: String = Bundle(for: SdkConfiguration.self).url(forResource: "Sdk", withExtension: "plist")?.path ?? ""
        self.applicationConfig = NSDictionary(contentsOfFile: path)!
    }
    
    public func getEventFlushFrequencyInSeconds() -> Int {
        guard let eventFlushFrequency = applicationConfig.object(forKey: "SWAARM_SDK_EVENT_FLUSH_FREQUENCY_IN_SECONDS") else {
            return 60
        }
        
        return Int(eventFlushFrequency as! String)!
    }
    
    public func getEventFlushBatchSize() -> Int {
        guard let eventFlushBatchSize = applicationConfig.object(forKey: "SWAARM_SDK_EVENT_FLUSH_BATCH_SIZE") else {
            return 50
        }
        
        return Int(eventFlushBatchSize as! String)!
    }
    
    public func getEventStorageSizeLimit() -> Int {
        guard let eventStorageSizeLimit = applicationConfig.object(forKey: "SWAARM_SDK_EVENT_STORAGE_SIZE_LIMIT") else {
            return 5000
        }
        
        return Int(eventStorageSizeLimit as! String)!
    }

}
