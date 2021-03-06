# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swaarm tracker.

The SDK is uses Swift and built with .framework support. Can be installed as Cocoapods Pod.

For example to load library using Cocoapods:

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

Create configuration object with swaarm event ingress hostname and access token.
This should be done in the startup method of your app, e.g. willFinishLaunchingWithOptions or didFinishLaunchingWithOptions, as it automatically fires the `__open` event and - on first start - the intial event.:
```
SwaarmAnalytics.configure(config: SwaarmConfig(appToken: "123456", eventIngressHostname: "https://tracker-domain.com"))
  
SwaarmAnalytics.configure(config: SwaarmConfig(appToken: "123456", eventIngressHostname: "https://tracker-domain.com", debug: true))
```

Send event (all parameters are optional):
```
SwaarmAnalytics.event("event_type_id", 123D, "custom value")
SwaarmAnalytics.event(typeId: "event_type_id", aggregatedValue: 123D, customValue: "custom value", revenue: 12.1)
```

Display details about tracking: `SwaarmAnalytics.debug(true)`

Disable tracking at runtime: `SwaarmAnalytics.disable()`

Enable tracking at runtime: `SwaarmAnalytics.enable()`
