//
//  PHORAppDelegate.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "Echo-Swift.h"
#import "Appirater.h"
#import <Google/Analytics.h>
#import "GAI.h"
#import "TDBadgedCell.h"

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
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    // Handle remote notification
    NSDictionary* userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
    }
    
    // Handle "please rate me"
    [Appirater setAppId:@"558585608"];
    [Appirater appLaunched:YES];
    
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app release
    
#if TARGET_IPHONE_SIMULATOR
    [GAI sharedInstance].logger.logLevel = kGAILogLevelNone;
#endif
    
    // http://stackoverflow.com/questions/10111369/unknown-class-zbarreaderview-in-interface-builder-file
    [TDBadgedCell class];
    
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *deviceTokenTrimmed = [deviceToken.description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenTrimmed = [deviceTokenTrimmed stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceTokenTrimmed forKey:@"deviceToken"];
    [defaults synchronize];
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
