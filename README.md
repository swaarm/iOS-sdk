# Summary

This is iOS SDK For Swaarm tracker. It provides API to send data to Swarm Tracking servers.
The API only provides low level device specific methods.

The SDK is written in Swift and build to .framework.Integrates with Cocoapods dependency manager.

For example to load library:

```
platform :ios, '10.0'
use_frameworks!

target 'Your-Target' do
  pod 'SwaarmSdk', '~> 0.2'
end
```
