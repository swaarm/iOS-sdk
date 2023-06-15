# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swaarm tracker.

The SDK can be added as a swift-package, simply search it by URL https://github.com/swaarm/iOS-sdk in File/Add Packages upper right corner.

To load the framework manually go to https://github.com/swaarm/iOS-sdk/releases and download the latest framework version.


### Usage

Import module:

```
import SwaarmSdk  // swift
@import SwaarmSdk;  // objective-c
```

Initialize the SDK with host and token, as received by our team.
This should be done in the startup method of your app, e.g. the init of your swiftui app, or the willFinishLaunchingWithOptions or didFinishLaunchingWithOptions, as it automatically fires the `__open` event and - on first start - the intial event.
The SDK determines if an app was installed before by checking and setting a keychain flag on first start. if it's indeed a reinstall, the `__reinstall` event is sent in lieu of the initial one.

To get additional debug output, set debug to true.

#### Swift

```
SwaarmAnalytics.configure(token: "123456", host: "https://tracker-domain.com")
SwaarmAnalytics.configure(token: "123456", host: "https://tracker-domain.com", debug: true)

```

Then send event (all parameters are optional):
```
SwaarmAnalytics.event("event_type_id", 123D, "custom value")
SwaarmAnalytics.event(typeId: "event_type_id", aggregatedValue: 123D, customValue: "custom value", revenue: 12.1)
SwaarmAnalytics.event(typeId: "buy_sword", revenue: 12.1)
```

#### Objective-C
```
    [SwaarmAnalytics configureWithToken: @"skhuehkpe72c0aoafxz0nqrfutmiolwt5tlp4no65ly" host: @"https://track.venus.swaarm-clients.com" batchSize:10 flushFrequency: 10 maxSize: 50 debug: YES];
    [SwaarmAnalytics eventWithTypeId:@"eventTypeId" aggregatedValue:0.0 customValue:@"custom" revenue:0.0];
```

send event will automatically enrich the event with some userdata, e.g. os_version, vendorId and - if available - idfa.
On devices using ios14 and up, tracking needs to be specifically requested to be able to get a non-zero idfa. To enable the idfa,
tracking needs to be requested from a visible app, as per https://stackoverflow.com/a/72287836/1768607


Disable tracking at runtime: `SwaarmAnalytics.disable()`

Enable tracking at runtime: `SwaarmAnalytics.enable()`
