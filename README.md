# Swaarm iOS SDK

A lightweight event tracking and attribution SDK for iOS. Only ~64KB including its single dependency (zlib for gzip compression).

**Requirements:** iOS 14.0+ | Swift 5.9+ | Xcode 15+

---

## Installation

### Swift Package Manager (recommended)

In Xcode: **File > Add Package Dependencies**, then enter:

```
https://github.com/swaarm/iOS-sdk
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swaarm/iOS-sdk", from: "2.0.1")
]
```

---

## Quick Start

```swift
import SwaarmSdk

// In your app's init or didFinishLaunchingWithOptions:
SwaarmAnalytics.configure(
    token: "your-token",
    host: "https://your-tracker-domain.com"
)
```

That's it. The SDK automatically sends an install (or reinstall) event on first launch and an `__open` event on every launch.

---

## Configuration

```swift
SwaarmAnalytics.configure(
    token: "your-token",                          // Required - provided by Swaarm
    host: "https://your-tracker-domain.com",      // Required - provided by Swaarm
    batchSize: 50,                                // Max events per batch (default: 50)
    flushFrequency: 2,                            // Seconds between flushes (default: 2)
    maxSize: 500,                                 // Max queued events in memory (default: 500)
    debug: false,                                 // Enable debug logging (default: false)
    attributionCallback: { data in                // Called when attribution data arrives
        print("Attribution: \(data)")
    },
    deferredDeepLinkCallback: { route in          // Called with deferred deep link on first launch
        print("Deep link: \(route)")
    }
)
```

An `async` version is also available:

```swift
await SwaarmAnalytics.configureAsync(
    token: "your-token",
    host: "https://your-tracker-domain.com"
)
```

---

## Event Tracking

### Custom Events

```swift
SwaarmAnalytics.event()
SwaarmAnalytics.event(typeId: "registration")
SwaarmAnalytics.event(typeId: "level_up", aggregatedValue: 5.0, customValue: "warrior")
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `typeId` | `String?` | `nil` | Event type identifier |
| `aggregatedValue` | `Double` | `0.0` | Numeric value for aggregation |
| `customValue` | `String` | `""` | Arbitrary string payload |

### In-App Purchases

```swift
SwaarmAnalytics.purchase(
    typeId: "premium_subscription",
    revenue: 9.99,
    currency: "USD",
    receipt: "base64-receipt-or-transactionId"
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `typeId` | `String?` | `nil` | Purchase event type |
| `revenue` | `Double` | `0.0` | Revenue amount |
| `currency` | `String?` | `nil` | Currency code (e.g. `"USD"`) |
| `receipt` | `String?` | `nil` | App Store receipt or transaction ID for verification |

---

## Attribution

The SDK automatically fetches attribution data from the server after initialization using exponential backoff. Once valid data arrives (with a postback decision), the `attributionCallback` is invoked and fetching stops.

Attribution data is cached locally and available at any time:

```swift
if let attribution = SwaarmAnalytics.attributionData {
    print("Campaign: \(attribution.offer?.campaignName ?? "unknown")")
    print("Publisher: \(attribution.publisher?.name ?? "unknown")")
    print("Decision: \(attribution.decision?.rawValue ?? "pending")")
}
```

### Attribution Data Structure

```
AttributionData
├── offer: AttributionOffer?
│   ├── id, name, lpId
│   ├── campaignId, campaignName
│   ├── adGroupId, adGroupName
│   └── adId, adName
├── publisher: AttributionPublisher?
│   ├── id, name, subId, subSubId
│   ├── site, placement, creative
│   ├── app, appId
│   ├── unique1, unique2, unique3
│   └── groupId
├── ids: AttributionIds?
│   ├── installId, clickId, userId
├── decision: PostbackDecision?    // .passed or .failed
└── googleInstallReferrer: GoogleInstallReferrerData?
    ├── gclid, gbraid, gadSource, wbraid
```

---

## Deferred Deep Links

On first app launch, the SDK checks for a deferred deep link from the server. If one exists, your callback is invoked with the route string:

```swift
SwaarmAnalytics.configure(
    token: "your-token",
    host: "https://your-tracker-domain.com",
    deferredDeepLinkCallback: { route in
        // Navigate to the deep link destination
        navigator.open(route)
    }
)
```

This only fires once (on the very first launch after install).

---

## IDFA & App Tracking Transparency

The SDK automatically reads the IDFA (Advertising Identifier) and includes it with events when available. On iOS 14.5+, you must request tracking permission via App Tracking Transparency before a non-zero IDFA is available.

Add `NSUserTrackingUsageDescription` to your `Info.plist`, then request permission from a visible view:

```swift
import AppTrackingTransparency

ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized:
        print("Tracking authorized")
    default:
        print("Tracking not authorized")
    }
}
```

See [Apple's documentation](https://developer.apple.com/documentation/apptrackingtransparency) for details. The SDK works without IDFA — it simply won't be included in events.

---

## Tracking Control

```swift
SwaarmAnalytics.disableTracking()   // Pause event flushing and attribution
SwaarmAnalytics.enableTracking()    // Resume
```

---

## Automatic Behavior

The SDK handles the following automatically:

| Behavior | Details |
|---|---|
| **Install detection** | Sends an initial event on first launch |
| **Reinstall detection** | Uses keychain persistence (survives uninstall) to detect reinstalls and sends `__reinstall` |
| **Open tracking** | Sends `__open` event on every initialization |
| **Event batching** | Queues events and flushes in configurable batches |
| **Gzip compression** | All HTTP request bodies are gzip-compressed |
| **Attribution fetching** | Polls server with exponential backoff until attribution data arrives |
| **Deep link resolution** | Checks for deferred deep links on first launch |
| **Privacy manifest** | Bundled `PrivacyInfo.xcprivacy` for App Store compliance |
