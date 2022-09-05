build: 
	#swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios10.0-simulator"
	xcodebuild build -sdk iphoneos -scheme SwaarmSdk -destination 'name=iPhone 12'

clean:
	rm -rf .build

test:
	xcodebuild test -sdk iphoneos -scheme SwaarmSdk -destination 'name=iPhone 12'
