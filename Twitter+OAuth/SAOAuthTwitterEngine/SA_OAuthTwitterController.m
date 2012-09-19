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
#import <QuartzCore/QuartzCore.h>

#import "SA_OAuthTwitterEngine.h"

#import "SA_OAuthTwitterController.h"

// Constants
static NSString* const kGGTwitterLoadingBackgroundImage = @"twitter_load.png";

@interface SA_OAuthTwitterController ()
@property (nonatomic, readonly) UIToolbar *pinCopyPromptBar;
@property (nonatomic, readwrite) UIInterfaceOrientation orientation;

- (id) initWithEngine: (SA_OAuthTwitterEngine *) engine andOrientation:(UIInterfaceOrientation)theOrientation;
//- (void) performInjection;
- (NSString *) locateAuthPinInWebView: (UIWebView *) webView;

- (void) showPinCopyPrompt;
- (void) gotPin: (NSString *) pin;
@end


@interface DummyClassForProvidingSetDataDetectorTypesMethod
- (void) setDataDetectorTypes: (int) types;
- (void) setDetectsPhoneNumbers: (BOOL) detects;
@end

@interface NSString (TwitterOAuth)
- (BOOL) oauthtwitter_isNumeric;
@end

@implementation NSString (TwitterOAuth)
- (BOOL) oauthtwitter_isNumeric {
	const char				*raw = (const char *) [self UTF8String];
	
	for (int i = 0; i < strlen(raw); i++) {
		if (raw[i] < '0' || raw[i] > '9') return NO;
	}
	return YES;
}
@end


@implementation SA_OAuthTwitterController
@synthesize engine = _engine, delegate = _delegate, navigationBar = _navBar, orientation = _orientation;


- (void) dealloc {
	[_backgroundView release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	_webView.delegate = nil;
	[_webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @""]]];
	[_webView release];
	
	self.view = nil;
	self.engine = nil;
	[super dealloc];
}

+ (SA_OAuthTwitterController *) controllerToEnterCredentialsWithTwitterEngine: (SA_OAuthTwitterEngine *) engine delegate: (id <SA_OAuthTwitterControllerDelegate>) delegate forOrientation: (UIInterfaceOrientation)theOrientation {
	if (![self credentialEntryRequiredWithTwitterEngine: engine]) return nil;			//not needed
	
	SA_OAuthTwitterController					*controller = [[[SA_OAuthTwitterController alloc] initWithEngine: engine andOrientation: theOrientation] autorelease];
	
	controller.delegate = delegate;
	return controller;
}

+ (SA_OAuthTwitterController *) controllerToEnterCredentialsWithTwitterEngine: (SA_OAuthTwitterEngine *) engine delegate: (id <SA_OAuthTwitterControllerDelegate>) delegate {
	return [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine: engine delegate: delegate forOrientation: UIInterfaceOrientationPortrait];
}


+ (BOOL) credentialEntryRequiredWithTwitterEngine: (SA_OAuthTwitterEngine *) engine {
	return ![engine isAuthorized];
}


- (id) initWithEngine: (SA_OAuthTwitterEngine *) engine andOrientation:(UIInterfaceOrientation)theOrientation {
	if ((self = [super init])) {
		self.engine = engine;
		if (!engine.OAuthSetup) [_engine requestRequestToken];
		self.orientation = theOrientation;
		_firstLoad = YES;
		
		if (UIInterfaceOrientationIsLandscape( self.orientation ) )
			_webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 32, 480, 288)];
		else
			_webView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 44, 320, 416)];
		
		_webView.alpha = 0.0;
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		if ([_webView respondsToSelector: @selector(setDetectsPhoneNumbers:)]) [(id) _webView setDetectsPhoneNumbers: NO];
		if ([_webView respondsToSelector: @selector(setDataDetectorTypes:)]) [(id) _webView setDataDetectorTypes: 0];
		
		NSURLRequest			*request = _engine.authorizeURLRequest;
		[_webView loadRequest: request];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pasteboardChanged:) name: UIPasteboardChangedNotification object: nil];
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

	_backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kGGTwitterLoadingBackgroundImage]];
	if ( UIInterfaceOrientationIsLandscape( self.orientation ) ) {
		self.view = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 480, 288)] autorelease];	
		_backgroundView.frame =  CGRectMake(0, 44, 480, 288);
		
		_navBar = [[[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 480, 32)] autorelease];
	} else {
		self.view = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 460)] autorelease];	
		_backgroundView.frame =  CGRectMake(0, 44, 320, 416);
		_navBar = [[[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, 44)] autorelease];
	}
	_navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	if (!UIInterfaceOrientationIsLandscape( self.orientation)) [self.view addSubview:_backgroundView];
	
	[self.view addSubview: _webView];
	[self.view addSubview: _navBar];
	
	_blockerView = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 200, 60)] autorelease];
	_blockerView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.8];
	_blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
	_blockerView.alpha = 0.0;
	_blockerView.clipsToBounds = YES;
	if ([_blockerView.layer respondsToSelector: @selector(setCornerRadius:)]) [(id) _blockerView.layer setCornerRadius: 10];
	
	UILabel								*label = [[[UILabel alloc] initWithFrame: CGRectMake(0, 5, _blockerView.bounds.size.width, 15)] autorelease];
	label.text = NSLocalizedString(@"Please Wait…", nil);
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	label.textAlignment = NSTextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize: 15];
	[_blockerView addSubview: label];
	
	UIActivityIndicatorView				*spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite] autorelease];
	
	spinner.center = CGPointMake(_blockerView.bounds.size.width / 2, _blockerView.bounds.size.height / 2 + 10);
	[_blockerView addSubview: spinner];
	[self.view addSubview: _blockerView];
	[spinner startAnimating];
	
	UINavigationItem				*navItem = [[[UINavigationItem alloc] initWithTitle: NSLocalizedString(@"Twitter Info", nil)] autorelease];
	navItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancel:)] autorelease];
	
	[_navBar pushNavigationItem: navItem animated: NO];
	[self locateAuthPinInWebView: nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation) fromInterfaceOrientation {
	self.orientation = self.interfaceOrientation;
	_blockerView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
//	[self performInjection];			//removed due to twitter update
}

//=============================================================================================================================
#pragma mark Notifications
- (void) pasteboardChanged: (NSNotification *) note {
	UIPasteboard					*pb = [UIPasteboard generalPasteboard];
	
	if ([note.userInfo objectForKey: UIPasteboardChangedTypesAddedKey] == nil) return;		//no meaningful change
	
	NSString						*copied = pb.string;
	
	if (copied.length != 7 || !copied.oauthtwitter_isNumeric) return;
	
	[self gotPin: copied];
}

//=============================================================================================================================
#pragma mark Webview Delegate stuff
- (void) webViewDidFinishLoad: (UIWebView *) webView {
	_loading = NO;
	//[self performInjection];
	if (_firstLoad) {
		[_webView performSelector: @selector(stringByEvaluatingJavaScriptFromString:) withObject: @"window.scrollBy(0,200)" afterDelay: 0];
		_firstLoad = NO;
	} else {
		NSString					*authPin = [self locateAuthPinInWebView: webView];

		if (authPin.length) {
			[self gotPin: authPin];
			return;
		}
		
		NSString					*formCount = [webView stringByEvaluatingJavaScriptFromString: @"document.forms.length"];
		
		if ([formCount isEqualToString: @"0"]) {
			[self showPinCopyPrompt];
		}
	}
	

	
	[UIView beginAnimations: nil context: nil];
	_blockerView.alpha = 0.0;
	[UIView commitAnimations];
	
	if ([_webView isLoading]) {
		_webView.alpha = 0.0;
	} else {
		_webView.alpha = 1.0;
	}
}

- (void) showPinCopyPrompt {
	if (self.pinCopyPromptBar.superview) return;		//already shown
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width / 2, self.pinCopyPromptBar.bounds.size.height / 2);
	[self.view insertSubview: self.pinCopyPromptBar belowSubview: self.navigationBar];
	
	[UIView beginAnimations: nil context: nil];
	self.pinCopyPromptBar.center = CGPointMake(self.pinCopyPromptBar.bounds.size.width / 2, self.navigationBar.bounds.size.height + self.pinCopyPromptBar.bounds.size.height / 2);
	[UIView commitAnimations];
}

/*********************************************************************************************************
 I am fully aware that this code is chock full 'o flunk. That said:
 
 - first we check, using standard DOM-diving, for the pin, looking at both the old and new tags for it.
 - if not found, we try a regex for it. This did not work for me (though it did work in test web pages).
 - if STILL not found, we iterate the entire HTML and look for an all-numeric 'word', 7 characters in length

Ugly. I apologize for its inelegance. Bleah.

*********************************************************************************************************/

- (NSString *) locateAuthPinInWebView: (UIWebView *) webView {
	// Look for either 'oauth-pin' or 'oauth_pin' in the raw HTML
	NSString			*js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; d;";
	NSString			*pin = [[webView stringByEvaluatingJavaScriptFromString: js] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (pin.length == 7) {
		return pin;
	} else {
		// New version of Twitter PIN page
		js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); " \
		"if (d) { var d2 = d.getElementsByTagName('code'); if (d2.length > 0) d2[0].innerHTML; }";
		pin = [[webView stringByEvaluatingJavaScriptFromString: js] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if (pin.length == 7) {
			return pin;
		}
	}
	
	return nil;
}

- (UIToolbar *) pinCopyPromptBar {
	if (_pinCopyPromptBar == nil){
		CGRect					bounds = self.view.bounds;
		
		_pinCopyPromptBar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 44, bounds.size.width, 44)] autorelease];
		_pinCopyPromptBar.barStyle = UIBarStyleBlackTranslucent;
		_pinCopyPromptBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;

		_pinCopyPromptBar.items = [NSArray arrayWithObjects: 
							  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease],
							  [[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Select and Copy the PIN", @"Select and Copy the PIN") style: UIBarButtonItemStylePlain target: nil action: nil] autorelease], 
							  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] autorelease], 
							nil];
	}
	
	return _pinCopyPromptBar;
}



//removed since Twitter changed the page format
//- (void) performInjection {
//	if (_loading) return;
//	
//	NSError					*error;
//	NSString				*filename = UIInterfaceOrientationIsLandscape(self.orientation ) ? @"jQueryInjectLandscape" : @"jQueryInject";
//	NSString				*path = [[NSBundle mainBundle] pathForResource: filename ofType: @"txt"];
//	
//    NSString *dataSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
//	
//    if (dataSource == nil) {
//        NSLog(@"An error occured while processing the jQueryInject file");
//    }
//	
//	[_webView stringByEvaluatingJavaScriptFromString:dataSource]; //This line injects the jQuery to make it look better	
//}

- (void) webViewDidStartLoad: (UIWebView *) webView {
	//[_activityIndicator startAnimating];
	_loading = YES;
	[UIView beginAnimations: nil context: nil];
	_blockerView.alpha = 1.0;
	[UIView commitAnimations];
}


- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
	NSData				*data = [request HTTPBody];
	char				*raw = data ? (char *) [data bytes] : "";
	
	if (raw && (strstr(raw, "cancel=") || strstr(raw, "deny="))) {
		[self denied];
		return NO;
	}
	if (navigationType != UIWebViewNavigationTypeOther) _webView.alpha = 0.1;
	return YES;
}

@end
