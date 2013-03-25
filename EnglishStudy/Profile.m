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
@synthesize nativeLanguageTag = _nativeLanguageTag;
@synthesize location = _location;
@synthesize photo = _photo;

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
    sharedInstance.username = [userProfile objectForKey:@"username"];
    sharedInstance.usercode = [userProfile objectForKey:@"usercode"];
    if (!sharedInstance.usercode) {
        sharedInstance.usercode = [defaults objectForKey:@"userGUID"];
        [defaults removeObjectForKey:@"userGUID"]; // deprecate 1.0.8, clean up backwards compatible
        needToSync = YES;
    }
    if (!sharedInstance.usercode) {
        sharedInstance.usercode = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        needToSync = YES;
    }
    sharedInstance.learningLanguageTag = [userProfile objectForKey:@"learningLanguageTag"];
    sharedInstance.nativeLanguageTag = [userProfile objectForKey:@"nativeLanguageTag"];
    sharedInstance.location = [userProfile objectForKey:@"location"];
    if ([userProfile objectForKey:@"photo"])
        sharedInstance.photo = [UIImage imageWithData:[userProfile objectForKey:@"photo"]];
    if (needToSync)
        [sharedInstance syncToDisk];
    return sharedInstance;
}

- (void)syncOnlineOnSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    NSAssert(self.usercode, @"Can only sync current user's profile");
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager syncCurrentUserProfileOnSuccess:success onFailure:failure];
}

- (void)syncToDisk{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userProfile = [NSMutableDictionary dictionary];
    [userProfile setObject:self.usercode forKey:@"usercode"];
    if (self.username)
        [userProfile setObject:self.username forKey:@"username"];
    if (self.learningLanguageTag)
        [userProfile setObject:self.learningLanguageTag forKey:@"learningLanguageTag"];
    if (self.nativeLanguageTag)
        [userProfile setObject:self.nativeLanguageTag forKey:@"nativeLanguageTag"];
    if (self.location)
        [userProfile setObject:self.location forKey:@"location"];
    if (self.photo)
        [userProfile setObject:UIImagePNGRepresentation(self.photo) forKey:@"photo"];
    [defaults setObject:userProfile forKey:@"userProfile"];
    [defaults synchronize];
}

- (NSNumber *)profileCompleteness
{
    float denominator = 5;
    float numerator = 0;
    if (self.username.length) numerator++;
    if (self.learningLanguageTag.length) numerator++;
    if (self.nativeLanguageTag.length) numerator++;
    if (self.location.length) numerator++;
    if (self.photo) numerator++;
    return [NSNumber numberWithFloat:numerator/denominator];
}

@end
