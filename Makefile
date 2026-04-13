build:
	xcodebuild build -sdk iphoneos -scheme SwaarmSdk -destination 'name=iPhone 16'

clean:
	rm -rf .build

test:
	xcodebuild test -sdk iphoneos -scheme SwaarmSdk -destination 'name=iPhone 16'
