

xcodebuild -target "OAuthLib" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos clean build
xcodebuild -target "OAuthLib" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphonesimulator clean build

lipo -create "Build/Debug-iphoneos/libOAuthConsumer_iPhone.a" "Build/Debug-iphonesimulator/libOAuthConsumer_iPhone.a" -output "../Twitter+OAuth/Libraries & Headers/libOAuth.a"
