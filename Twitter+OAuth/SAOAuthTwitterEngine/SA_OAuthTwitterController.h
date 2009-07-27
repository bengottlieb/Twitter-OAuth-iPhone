//
//  SA_OAuthTwitterController.h
//
//  Created by Ben Gottlieb on 24 July 2009.
//  Copyright 2009 Stand Alone, Inc.
//
//  Some code and concepts taken from examples provided by 
//  Matt Gemmell, Chris Kimpton, and Isaiah Carew
//  See ReadMe for further attributions, copyrights and license info.
//

#import <UIKit/UIKit.h>

@class SA_OAuthTwitterEngine, SA_OAuthTwitterController;

@protocol SA_OAuthTwitterControllerDelegate <NSObject>
@optional
- (void) OAuthTwitterController: (SA_OAuthTwitterController *) controller authenticatedWithUsername: (NSString *) username;
- (void) OAuthTwitterControllerFailed: (SA_OAuthTwitterController *) controller;
- (void) OAuthTwitterControllerCanceled: (SA_OAuthTwitterController *) controller;
@end


@interface SA_OAuthTwitterController : UIViewController <UIWebViewDelegate> {

	SA_OAuthTwitterEngine						*_engine;
	UIWebView									*_webView;
	UINavigationBar								*_navBar;
	
	id <SA_OAuthTwitterControllerDelegate>		_delegate;
	UIActivityIndicatorView						*_activityIndicator;
}


@property (nonatomic, readwrite, retain) SA_OAuthTwitterEngine *engine;
@property (nonatomic, readwrite, assign) id <SA_OAuthTwitterControllerDelegate> delegate;
@property (nonatomic, readonly) UINavigationBar *navigationBar;

+ (SA_OAuthTwitterController *) controllerToEnterCredentialsWithTwitterEngine: (SA_OAuthTwitterEngine *) engine delegate: (id <SA_OAuthTwitterControllerDelegate>) delegate;
+ (BOOL) credentialEntryRequiredWithTwitterEngine: (SA_OAuthTwitterEngine *) engine;


- (id) initWithEngine: (SA_OAuthTwitterEngine *) engine;
@end
