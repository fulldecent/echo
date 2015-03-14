//
//  PHORAppDelegate.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "Profile.h"
#import "Appirater.h"
#import "GAI.h"
#import "TDBadgedCell.h"
#import "GoogleConversionPing.h"

@implementation AppDelegate
@synthesize window = _window;

/*
 void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}
*/

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // Handle "please rate me"
    [Appirater setAppId:@"558585608"];
    
    // Deprecate 1.0.8, for upgrade
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"learningLanguageTag"];
    [defaults removeObjectForKey:@"nativeLanguageTag"];
    [defaults removeObjectForKey:@"lastUpdatePracticeList"]; // Upgrade / Backwards compatibility for <= 1.0.9
    [defaults synchronize];
    
    // http://www.switchonthecode.com/tutorials/an-absolute-beginners-guide-to-iphone-development
    [_window makeKeyAndVisible];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    // Handle remote notification
    NSDictionary* userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
    }
    
    [Appirater appLaunched:YES];
    
    // https://developers.google.com/analytics/devguides/collection/ios/v3/
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-52764-16"];
    
#if TARGET_IPHONE_SIMULATOR
    [[GAI sharedInstance] setDryRun:YES];
#endif
    
    // http://stackoverflow.com/questions/10111369/unknown-class-zbarreaderview-in-interface-builder-file
    [TDBadgedCell class];
    
    [GoogleConversionPing pingWithConversionId:@"1070788746"
                                         label:@"jTQnCLzisQcQiuHL_gM"
                                         value:@"2.8"
                                  isRepeatable:NO];

    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceTokenTrimmed = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenTrimmed = [deviceTokenTrimmed stringByReplacingOccurrencesOfString:@" " withString:@""];
    me.deviceToken = deviceTokenTrimmed;
    [me syncToDisk];
    
	NSLog(@"My token is: %@", deviceTokenTrimmed);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
}

@end
