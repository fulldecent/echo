//
//  PHORAppDelegate.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworking.h"
#import "Profile.h"
#import "Appirater.h"

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
    
    if ([self.window respondsToSelector:@selector(setTintColor:)])
        self.window.tintColor = [UIColor colorWithRed:0x91/255.0 green:0x80/255.0 blue:0x08/255.0 alpha:1];
    
//    [UIColor purpleColor];
    
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
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
    }
    
    [Appirater appLaunched:YES];

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
}

@end
