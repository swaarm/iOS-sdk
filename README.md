# Swaarm SDK (iOS)

Swaarm SDK is tiny and only uses one library for gzip. Including libraries, it's only 64K.
To use the SDK is as simple as following these 3 steps:

## 1 Add Package to XCode

The SDK can be added as a swift-package, simply search it by URL https://github.com/swaarm/iOS-sdk in `File`/`Add Packages`, upper right corner search box.

To manually integrate the SDK go to https://github.com/swaarm/iOS-sdk/releases and download the latest framework version.


## 2 Import & Initialize the SDK

Initialize the SDK with host and token, as received by our team.
This should be done in the startup method of your app, e.g. the `init` of your swiftui app, or the `willFinishLaunchingWithOptions` or `didFinishLaunchingWithOptions`, as it automatically fires the `__open` event and - on first start - the intial event.
The SDK determines if an app was installed before by checking and setting a keychain flag on first start. if it's indeed a reinstall, the `__reinstall` event is sent in lieu of the initial one.

To get additional debug output, set debug to true.

sent events will automatically be enriched with some userdata, e.g. os_version, vendorId and - if available - idfa.
On devices using ios14 and up, tracking needs to be specifically requested to be able to get a non-zero idfa. To enable the idfa,
tracking needs to be requested from a visible app, as per https://stackoverflow.com/a/72287836/1768607

purchase is a special form of event, where you can supply revenue, currency and the receipt/transactionId to verify the purchase instead of supplying the usual aggregatedValue and customValue.

### Swift

```
    import SwaarmSdk
    SwaarmAnalytics.configure(token: "123456", host: "https://tracker-domain.com", debug: true)
    SwaarmAnalytics.event(typeId: "event_type_id", aggregatedValue: 123D, customValue: "custom value")
    SwaarmAnalytics.purchase(typeId: "event_type_id", revenue: 12.0, currency: "USD", receipt: "base64 receipt or transactionId")
```

### Objective-C
```
    @import SwaarmSdk;
    [SwaarmAnalytics configureWithToken: @"123456" host: @"https://tracker-domain.com" batchSize:10 flushFrequency: 10 maxSize: 50 debug: YES];
    [SwaarmAnalytics eventWithTypeId:@"eventTypeId" aggregatedValue:0.0 customValue:@"custom"];
    [SwaarmAnalytics purchaseWithTypeId:@"eventTypeId" revenue:0.0 currency:@"USD" receipt:@"base64 receipt or transactionId"];
```

## 3 Build your App and Publish it

Yes, of course you still need to build and distribute your app. but apart from that, we're done! simple as that 🤩 👍
