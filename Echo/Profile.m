//
//  Profile.m
//  Echo
//
//  Created by Will Entriken on 3/2/13.
//
//

#import "Profile.h"
#import "NetworkManager.h"
#import "AppDelegate.h"
#import <NSData+Base64.h>

@implementation Profile
@synthesize userID = _userID;
@synthesize username = _username;
@synthesize usercode = _usercode;
@synthesize learningLanguageTag = _languageTag;
@synthesize nativeLanguageTag = _nativeLanguageTag;
@synthesize location = _location;
@synthesize photo = _photo;
@synthesize deviceToken = _deviceToken;

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
    sharedInstance.username = userProfile[@"username"];
    if (!sharedInstance.username) {
        sharedInstance.username = [NSString stringWithFormat:@"user%d", arc4random()%1000000];
        needToSync = YES;
    }    
    sharedInstance.usercode = userProfile[@"usercode"];
    sharedInstance.userID = userProfile[@"userID"];
    if (!sharedInstance.usercode) { // deprecate 1.0.8, clean up backwards compatible
        sharedInstance.usercode = [defaults objectForKey:@"userGUID"];
        needToSync = YES;
    }
    if ([defaults objectForKey:@"userGUID"]) { // deprecate 1.0.8, clean up backwards compatible
        [defaults removeObjectForKey:@"userGUID"];
        [defaults synchronize];
    }
    if (!sharedInstance.usercode) {
        sharedInstance.usercode = [UIDevice currentDevice].identifierForVendor.UUIDString;
        needToSync = YES;
    }
    sharedInstance.learningLanguageTag = userProfile[@"learningLanguageTag"];
    sharedInstance.nativeLanguageTag = userProfile[@"nativeLanguageTag"];
    sharedInstance.location = userProfile[@"location"];
    if (userProfile[@"photo"])
        sharedInstance.photo = [UIImage imageWithData:userProfile[@"photo"]];
    if (needToSync)
        [sharedInstance syncToDisk];
    return sharedInstance;
}

- (void)syncOnlineOnSuccess:(void(^)(NSArray *recommendedLessons))success onFailure:(void(^)(NSError *error))failure
{
    NSAssert(self.usercode, @"Can only sync current user's profile");
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager postUserProfile:self onSuccess:^(NSString *username, NSNumber *userID, NSArray *recommendedLessons)
     {
         self.username = username;
         self.userID = userID;
         [self syncToDisk];
         if (success)
             success(recommendedLessons);
     } onFailure:^(NSError *error) {
         if (failure)
             failure(error);
     }];
}

- (void)syncToDisk{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userProfile = [NSMutableDictionary dictionary];
    userProfile[@"usercode"] = self.usercode;
    if (self.username)
        userProfile[@"username"] = self.username;
    if (self.learningLanguageTag)
        userProfile[@"learningLanguageTag"] = self.learningLanguageTag;
    if (self.nativeLanguageTag)
        userProfile[@"nativeLanguageTag"] = self.nativeLanguageTag;
    if (self.location)
        userProfile[@"location"] = self.location;
    if (self.photo)
        userProfile[@"photo"] = UIImagePNGRepresentation(self.photo);
    if (self.userID)
        userProfile[@"userID"] = self.userID;
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
    return @(numerator/denominator);
}

// http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;
{
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    CGImageRef imageRef = sourceImage.CGImage;
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    }
    
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, M_PI_2); // + 90 degrees
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, -M_PI_2); // - 90 degrees
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, -M_PI); // - 180 degrees
    }
    
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return newImage;
}

- (NSDictionary *)toDictionary
{
    Profile *me = [Profile currentUserProfile];
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    retval[@"username"] = me.username;
    retval[@"userCode"] = me.usercode;
    if (me.learningLanguageTag)
        retval[@"learningLanguageTag"] = me.learningLanguageTag;
    if (me.nativeLanguageTag)
        retval[@"nativeLanguageTag"] = me.nativeLanguageTag;
    if (me.location)
        retval[@"location"] = me.location;
    if (me.deviceToken)
        retval[@"deviceToken"] = me.deviceToken;
    if (me.photo) {
        UIImage *thumbnail = [Profile imageWithImage:me.photo scaledToSizeWithSameAspectRatio:CGSizeMake(100, 100)];
        NSData *JPEGdata = UIImageJPEGRepresentation(thumbnail, 0.8);
        retval[@"photo"] = [JPEGdata base64EncodedString];
    }
    return retval;
}

- (NSData *)JSON
{
    return [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:nil];
}

@end
