//
//  Profile.h
//  Echo
//
//  Created by Will Entriken on 3/2/13.
//
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject
@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *usercode;
@property (strong, nonatomic) NSString *learningLanguageTag;
@property (strong, nonatomic) NSString *nativeLanguageTag;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) UIImage *photo;
@property (strong, nonatomic) NSString *deviceToken;

+ (Profile *)currentUserProfile;
- (void)syncOnlineOnSuccess:(void(^)(NSArray *recommendedLessons))success onFailure:(void(^)(NSError *error))failure;
- (void)syncToDisk;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *profileCompleteness;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *JSON;
@end
