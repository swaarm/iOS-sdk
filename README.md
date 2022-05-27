# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swarm Tracking servers.
The API only provides low level device specific methods.

The SDK is written in Swift and build to .framework. Integrates with Cocoapods dependency manager.

For example to load library using Cocaods:

```
platform :ios, '10.0'
use_frameworks!

target 'Your-Target' do
  pod 'SwaarmSdk', '~> 0.2'
end
```

To load framework manually go to https://github.com/swaarm/iOS-sdk/releases and download latest framework version.


### Usage

Import module:

```
import SwaarmSdk
```

Create configuration object with swaarm event ingress hostname and access token:
```
SwaarmAnalytics.configure(config: SwaarmConfig(appToken: "123456", eventIngressHostname: "https://tracker-domain.com"))
  
SwaarmAnalytics.debug(enable: true) //Will print some debug information to console
```

Send event:
```
SwaarmAnalytics.event("event_type_id", 123D, "custom value")
```

Display details about tracking: `SwaarmAnalytics.debug(true)`

Disable tracking at runtime: `SwaarmAnalytics.disable()`

Enable tracking at runtime: `SwaarmAnalytics.enable()`
