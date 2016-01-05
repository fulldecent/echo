//
//  Event.h
//  Echo
//
//  Created by William Entriken on 9/28/14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, EventTypes) {EventTypePostLesson, EventTypeLikeLesson, EventTypeFlagLesson, EventTypeFlagUser, EventTypeUpdateUser, EventTypePostPractice, EventTypeFeedbackLesson, EventTypeReplyPractice};

@interface Event : NSObject
@property (strong, nonatomic) NSNumber *eventID;
@property (nonatomic) EventTypes eventType;
@property (strong, nonatomic) NSNumber *timestamp;
@property (strong, nonatomic) NSNumber *actingUserID;
@property (strong, nonatomic) NSNumber *targetUserID;
@property (strong, nonatomic) NSNumber *targetWordID;
@property (strong, nonatomic) NSNumber *targetLessonID;
@property (strong, nonatomic) NSString *htmlDescription;
@property (strong, nonatomic) NSNumber *wasRead;

@property (nonatomic) NSString *actingUserName; // hack
@property (nonatomic) NSString *targetWordName; // hack

+ (Event *)eventWithDictionary:(NSDictionary *)dictionary;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *toDictionary;
+ (Event *)eventWithJSON:(NSData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *JSON;
@end
