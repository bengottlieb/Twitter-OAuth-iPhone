//
//  SA_OAuthTwitterController.m
//
//  Created by Ben Gottlieb on 24 July 2009.
//  Copyright 2009 Stand Alone, Inc.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell, Chris Kimpton, and Isaiah Carew
//  See ReadMe for further attributions, copyrights and license info.
//

#import <UIKit/UIKit.h>

#import "SA_OAuthTwitterEngine.h"

#import "SA_OAuthTwitterController.h"

@interface DummyClassForProvidingSetDataDetectorTypesMethod
- (void) setDataDetectorTypes: (int) types;
- (void) setDetectsPhoneNumbers: (BOOL) detects;
@end

@implementation SA_OAuthTwitterController
@synthesize engine = _engine, delegate = _delegate, navigationBar = _navBar;


- (void) dealloc {
	_webView.delegate = nil;
	[_webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @""]]];
	[_webView release];
	
	[_activityIndicator release];
	_activityIndicator = nil;
	self.view = nil;
	self.engine = nil;
	[super dealloc];
}

+ (SA_OAuthTwitterController *) controllerToEnterCredentialsWithTwitterEngine: (SA_OAuthTwitterEngine *) engine delegate: (id <SA_OAuthTwitterControllerDelegate>) delegate {
	if (![self credentialEntryRequiredWithTwitterEngine: engine]) return nil;			//not needed
	
	SA_OAuthTwitterController					*controller = [[[SA_OAuthTwitterController alloc] initWithEngine: engine] autorelease];
	
	controller.delegate = delegate;
	return controller;
}

+ (BOOL) credentialEntryRequiredWithTwitterEngine: (SA_OAuthTwitterEngine *) engine {
	return ![engine isAuthorized];
}


- (id) initWithEngine: (SA_OAuthTwitterEngine *) engine {
	if (self = [super init]) {
		self.engine = engine;

		_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
		_activityIndicator.hidesWhenStopped = YES;

		_webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 44, 320, 416)];
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		if ([_webView respondsToSelector: @selector(setDetectsPhoneNumbers:)]) [(id) _webView setDetectsPhoneNumbers: NO];
		if ([_webView respondsToSelector: @selector(setDataDetectorTypes:)]) [(id) _webView setDataDetectorTypes: 0];
		
		NSURLRequest			*request = _engine.authorizeURLRequest;
		
		[_webView loadRequest: request];
	}
	return self;
}

//=============================================================================================================================
#pragma mark Actions
- (void) denied {
	if ([_delegate respondsToSelector: @selector(OAuthTwitterControllerFailed:)]) [_delegate OAuthTwitterControllerFailed: self];
	[self performSelector: @selector(dismissModalViewControllerAnimated:) withObject: (id) kCFBooleanTrue afterDelay: 1.0];
}

- (void) gotPin: (NSString *) pin {
	_engine.pin = pin;
	[_engine requestAccessToken];
	
	if ([_delegate respondsToSelector: @selector(OAuthTwitterController:authenticatedWithUsername:)]) [_delegate OAuthTwitterController: self authenticatedWithUsername: _engine.username];
	[self performSelector: @selector(dismissModalViewControllerAnimated:) withObject: (id) kCFBooleanTrue afterDelay: 1.0];
}

- (void) cancel: (id) sender {
	if ([_delegate respondsToSelector: @selector(OAuthTwitterControllerCanceled:)]) [_delegate OAuthTwitterControllerCanceled: self];
	[self performSelector: @selector(dismissModalViewControllerAnimated:) withObject: (id) kCFBooleanTrue afterDelay: 0.0];
}

//=============================================================================================================================
#pragma mark View Controller Stuff
- (void) loadView {
	[super loadView];
	self.view = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 416)] autorelease];
	[self.view addSubview: _webView];
	
	_navBar = [[[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, 44)] autorelease];
	[self.view addSubview: _navBar];
	
	UINavigationItem				*navItem = [[[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Twitter Info", @"Twitter Info")] autorelease];
	navItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancel:)] autorelease];
	navItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: _activityIndicator] autorelease];
	
	[_navBar pushNavigationItem: navItem animated: NO];
	
}


//=============================================================================================================================
#pragma mark Webview Delegate stuff
- (void) webViewDidFinishLoad: (UIWebView *) webView {
	NSError *error;
	NSString *path = [[NSBundle mainBundle] pathForResource: @"jQueryInject" ofType: @"txt"];
    NSString *dataSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if (dataSource == nil) {
        NSLog(@"An error occured while processing the jQueryInject file");
    }
	
	[_webView stringByEvaluatingJavaScriptFromString:dataSource]; //This line injects the jQuery to make it look better
	
	NSString					*authPin = [[_webView stringByEvaluatingJavaScriptFromString: @"document.getElementById('oauth_pin').innerHTML"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (authPin.length == 0) authPin = [[_webView stringByEvaluatingJavaScriptFromString: @"document.getElementById('oauth_pin').getElementsByTagName('a')[0].innerHTML"] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

	[_activityIndicator stopAnimating];
	if (authPin.length) {
		[self gotPin: authPin];
	} 
}

- (void) webViewDidStartLoad: (UIWebView *) webView {
	[_activityIndicator startAnimating];
}


- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
	NSData				*data = [request HTTPBody];
	char				*raw = data ? (char *) [data bytes] : "";
	
	if (raw && strstr(raw, "cancel=Deny")) {
		[self denied];
		return NO;
	}

	return YES;
}

@end
