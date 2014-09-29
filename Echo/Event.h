//
//  Event.h
//  Echo
//
//  Created by William Entriken on 9/28/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {EventTypePostLesson, EventTypeLikeLesson, EventTypeFlagLesson, EventTypeFlagUser, EventTypeUpdateUser, EventTypePostPractice, EventTypeFeedbackLesson, EventTypeReplyPractice} EventTypes;

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
+ (Event *)eventWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
+ (Event *)eventWithJSON:(NSData *)data;
- (NSData *)JSON;
@end
