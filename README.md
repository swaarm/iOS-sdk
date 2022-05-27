# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swaarm tracker.

The SDK is uses Swift and built with .framework support. Can be installed as Cocoapods Pod.

For example to load library using Cocoads:

```
platform :ios, '10.0'
use_frameworks!

target 'Your-Target' do
  pod 'SwaarmSdk', '~> x.x.x'
  //OR
  pod 'SwaarmSdk', :git => 'https://github.com/swaarm/iOS-sdk', :tag => 'x.x.x'
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
