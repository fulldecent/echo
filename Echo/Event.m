//
//  Event.m
//  Echo
//
//  Created by William Entriken on 9/28/14.
//
//

#import "Event.h"

#define kEventID @"id"
#define kEventType @"eventType"
#define kTimestamp @"timestamp"
#define kActingUserID @"actingUserID"
#define kTargetUserID @"targetUserID"
#define kTargetWordID @"targetWordID"
#define kTargetLessonID @"targetLessonID"
#define kHtmlDescription @"description"
#define kWasRead @"wasRead"

// hacks
#define kActingUserName @"actingUserName"
#define kTargetWordName @"targetWordName"

#define kEventTypePostLesson @"postLesson"
#define kEventTypeLikeLesson @"likeLesson"
#define kEventTypeFlagLesson @"flagLesson"
#define kEventTypeFlagUser @"flagUser"
#define kEventTypeUpdateUser @"updateUser"
#define kEventTypePostPractice @"postPractice"
#define kEventTypeFeedbackLesson @"feedbackLesson"
#define kEventTypeReplyPractice @"replyPractice"

@implementation Event

+ (Event *)eventWithDictionary:(NSDictionary *)packed
{
    Event *retval = [[Event alloc] init];
    if (packed[kEventID])
        retval.eventID = packed[kEventID];
    if (packed[kTimestamp])
        retval.timestamp = packed[kTimestamp];
    if (packed[kActingUserID])
        retval.actingUserID = packed[kActingUserID];
    if (packed[kTargetUserID])
        retval.targetUserID = packed[kTargetUserID];
    if (packed[kTargetWordID])
        retval.targetWordID = packed[kTargetWordID];
    if (packed[kTargetLessonID])
        retval.targetLessonID = packed[kTargetLessonID];
    if (packed[kHtmlDescription])
        retval.htmlDescription = packed[kHtmlDescription];
    if (packed[kWasRead])
        retval.wasRead = packed[kWasRead];

    // hacks
    if (packed[kActingUserName])
        retval.actingUserName = packed[kActingUserName];
    if (packed[kTargetWordName])
        retval.targetWordName = packed[kTargetWordName];
    
    if (packed[kEventType]) {
        if ([packed[kEventType] isKindOfClass:[NSNumber class]]) {
            retval.eventType = ((NSNumber *)packed[kEventType]).intValue;
        } else if ([packed[kEventType] isKindOfClass:[NSString class]]) {
            NSString *type = (NSString *)packed[kEventType];
            if ([type isEqualToString:kEventTypePostLesson])
                retval.eventType = EventTypePostLesson;
            else if ([type isEqualToString:kEventTypeLikeLesson])
                retval.eventType = EventTypeLikeLesson;
            else if ([type isEqualToString:kEventTypeFlagLesson])
                retval.eventType = EventTypeFlagLesson;
            else if ([type isEqualToString:kEventTypeFlagUser])
                retval.eventType = EventTypeFlagUser;
            else if ([type isEqualToString:kEventTypeUpdateUser])
                retval.eventType = EventTypeUpdateUser;
            else if ([type isEqualToString:kEventTypePostPractice])
                retval.eventType = EventTypePostPractice;
            else if ([type isEqualToString:kEventTypeFeedbackLesson])
                retval.eventType = EventTypeFeedbackLesson;
            else if ([type isEqualToString:kEventTypeReplyPractice])
                retval.eventType = EventTypeReplyPractice;
        }
    }
    
    return retval;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    if (self.eventID)
        retval[kEventID] = self.eventID;
    if (self.timestamp)
        retval[kTimestamp] = self.timestamp;
    if (self.actingUserID)
        retval[kActingUserID] = self.actingUserID;
    if (self.targetUserID)
        retval[kTargetUserID] = self.targetUserID;
    if (self.targetWordID)
        retval[kTargetWordID] = self.targetWordID;
    if (self.targetLessonID)
        retval[kTargetLessonID] = self.targetLessonID;
    if (self.htmlDescription)
        retval[kHtmlDescription] = self.htmlDescription;
    if (self.wasRead)
        retval[kWasRead] = self.wasRead;

    if (self.eventType) {
        switch (self.eventType) {
            case EventTypePostLesson:
                retval[kEventType] = kEventTypePostLesson;
                break;
            case EventTypeLikeLesson:
                retval[kEventType] = kEventTypeLikeLesson;
                break;
            case EventTypeFlagLesson:
                retval[kEventType] = kEventTypeFlagLesson;
                break;
            case EventTypeFlagUser:
                retval[kEventType] = kEventTypeFlagUser;
                break;
            case EventTypeUpdateUser:
                retval[kEventType] = kEventTypeUpdateUser;
                break;
            case EventTypePostPractice:
                retval[kEventType] = kEventTypePostPractice;
                break;
            case EventTypeFeedbackLesson:
                retval[kEventType] = kEventTypeFeedbackLesson;
                break;
            case EventTypeReplyPractice:
                retval[kEventType] = kEventTypeReplyPractice;
                break;
            default:
                break;
        }
    }
    return retval;
}

+ (Event *)eventWithJSON:(NSData *)data
{
    NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [Event eventWithDictionary:packed];
}

- (NSData *)JSON
{
    return [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:nil];
}

@end
