# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swaarm tracker.

The SDK uses Swift and is built with .framework support, simply add it by URL https://github.com/swaarm/iOS-sdk

To load framework manually go to https://github.com/swaarm/iOS-sdk/releases and download latest framework version.


### Usage

Import module:

```
import SwaarmSdk
```

Create configuration object with swaarm event ingress hostname and access token.
This should be done in the startup method of your app, e.g. the init of your swiftui app, or the willFinishLaunchingWithOptions or didFinishLaunchingWithOptions, as it automatically fires the `__open` event and - on first start - the intial event.:
```
SwaarmAnalytics.configure(token: "123456", host: "https://tracker-domain.com")
  
SwaarmAnalytics.configure(token: "123456", host: "https://tracker-domain.com", debug: true)
```

Send event (all parameters are optional):
```
SwaarmAnalytics.event("event_type_id", 123D, "custom value")
SwaarmAnalytics.event(typeId: "event_type_id", aggregatedValue: 123D, customValue: "custom value", revenue: 12.1)
SwaarmAnalytics.event(typeId: "buy_sword", revenue: 12.1)
```


Disable tracking at runtime: `SwaarmAnalytics.disable()`

Enable tracking at runtime: `SwaarmAnalytics.enable()`
