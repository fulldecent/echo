//
//  AppDelegate.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import UIKit
import Google
import Appirater

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // https://developers.google.com/analytics/devguides/collection/ios/v3/?ver=swift
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        
        // Handle "please rate me"
        Appirater.setAppId("558585608")
        Appirater.appLaunched(true)

        // Let the device know we want to receive push notifications
        UIApplication.sharedApplication().registerForRemoteNotifications()
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] {
            NSNotificationCenter.defaultCenter().postNotificationName("pushNotification", object: nil, userInfo: userInfo as? [NSObject : AnyObject])
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var deviceTokenTrimmed: String = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        deviceTokenTrimmed = deviceTokenTrimmed.stringByReplacingOccurrencesOfString(" ", withString: "")
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(deviceTokenTrimmed, forKey: "deviceToken")
        defaults.synchronize()
        NSLog("My token is: %@", deviceTokenTrimmed)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("Failed to get token, error: %@", error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSNotificationCenter.defaultCenter().postNotificationName("pushNotification", object: nil, userInfo: userInfo)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
