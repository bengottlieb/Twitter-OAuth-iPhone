To build a combined library for use in both the sim and on device, build both individual libraries, then cd to the build directory in terminal and execute the following:

lipo -create Release-iphoneos/libOAuthConsumer_iPhone.a Debug-iphonesimulator/libOAuthConsumer_iPhone.a -output libOAuth.a
