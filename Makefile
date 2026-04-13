build:
	xcodebuild build -scheme SwaarmSdk -destination 'generic/platform=iOS Simulator'

clean:
	rm -rf .build

test:
	xcodebuild test -scheme SwaarmSdk -destination 'platform=iOS Simulator,name=iPhone 16'
