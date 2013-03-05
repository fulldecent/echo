//
//  Profile.h
//  Echo
//
//  Created by Will Entriken on 3/2/13.
//
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *usercode;
@property (strong, nonatomic) NSString *learningLanguageTag;

+ (Profile *)currentUserProfile;
- (void)syncOnlineOnSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)syncToDisk;
@end
