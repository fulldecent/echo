//
//  Profile.m
//  Echo
//
//  Created by Will Entriken on 3/2/13.
//
//

#import "Profile.h"
#import "NetworkManager.h"

@implementation Profile
@synthesize username = _username;
@synthesize usercode = _usercode;
@synthesize learningLanguageTag = _languageTag;

+ (Profile *)currentUserProfile
{
    static Profile *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Profile alloc] init];
    });
    
    if (sharedInstance.usercode) return sharedInstance;
    
    BOOL needToSync = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userProfile = [defaults objectForKey:@"userProfile"];
    if (!userProfile)
        userProfile = [NSMutableDictionary dictionary];
    sharedInstance.username = [userProfile valueForKey:@"username"];
    sharedInstance.usercode = [userProfile valueForKey:@"userCode"];
    sharedInstance.learningLanguageTag = [userProfile valueForKey:@"learningLanguageTag"];
    if (!sharedInstance.usercode)
        sharedInstance.usercode = [defaults objectForKey:@"userGUID"];
    if (!sharedInstance.usercode) {
        sharedInstance.usercode = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        needToSync = YES;
    }
    if (needToSync)
        [sharedInstance syncToDisk];
    return sharedInstance;
}

- (void)syncOnlineOnSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    NSAssert(self.usercode, @"Can only sync current user's profile");
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager syncProfile:self onSuccess:success onFailure:failure];
}

- (void)syncToDisk{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userProfile = [NSMutableDictionary dictionary];
    [userProfile setObject:self.username forKey:@"username"];
    [userProfile setObject:self.usercode forKey:@"usercode"];
    [userProfile setObject:self.learningLanguageTag forKey:@"learningLanguageTag"];
    [defaults setObject:userProfile forKey:@"userProfile"];
}

@end
