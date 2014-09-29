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
    if ([packed objectForKey:kEventID])
        retval.eventID = [packed objectForKey:kEventID];
    if ([packed objectForKey:kTimestamp])
        retval.timestamp = [packed objectForKey:kTimestamp];
    if ([packed objectForKey:kActingUserID])
        retval.actingUserID = [packed objectForKey:kActingUserID];
    if ([packed objectForKey:kTargetUserID])
        retval.targetUserID = [packed objectForKey:kTargetUserID];
    if ([packed objectForKey:kTargetWordID])
        retval.targetWordID = [packed objectForKey:kTargetWordID];
    if ([packed objectForKey:kTargetLessonID])
        retval.targetLessonID = [packed objectForKey:kTargetLessonID];
    if ([packed objectForKey:kHtmlDescription])
        retval.htmlDescription = [packed objectForKey:kHtmlDescription];
    if ([packed objectForKey:kWasRead])
        retval.wasRead = [packed objectForKey:kWasRead];
    
    if ([packed objectForKey:kEventType]) {
        if ([[packed objectForKey:kEventType] isKindOfClass:[NSNumber class]]) {
            retval.eventType = [(NSNumber *)[packed objectForKey:kEventType] intValue];
        } else if ([[packed objectForKey:kEventType] isKindOfClass:[NSString class]]) {
            NSString *type = (NSString *)[packed objectForKey:kEventType];
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
        [retval setObject:self.eventID forKey:kEventID];
    if (self.timestamp)
        [retval setObject:self.timestamp forKey:kTimestamp];
    if (self.actingUserID)
        [retval setObject:self.actingUserID forKey:kActingUserID];
    if (self.targetUserID)
        [retval setObject:self.targetUserID forKey:kTargetUserID];
    if (self.targetWordID)
        [retval setObject:self.targetWordID forKey:kTargetWordID];
    if (self.targetLessonID)
        [retval setObject:self.targetLessonID forKey:kTargetLessonID];
    if (self.htmlDescription)
        [retval setObject:self.htmlDescription forKey:kHtmlDescription];
    if (self.wasRead)
        [retval setObject:self.wasRead forKey:kWasRead];

    if (self.eventType) {
        switch (self.eventType) {
            case EventTypePostLesson:
                [retval setObject:kEventTypePostLesson forKey:kEventType];
                break;
            case EventTypeLikeLesson:
                [retval setObject:kEventTypeLikeLesson forKey:kEventType];
                break;
            case EventTypeFlagLesson:
                [retval setObject:kEventTypeFlagLesson forKey:kEventType];
                break;
            case EventTypeFlagUser:
                [retval setObject:kEventTypeFlagUser forKey:kEventType];
                break;
            case EventTypeUpdateUser:
                [retval setObject:kEventTypeUpdateUser forKey:kEventType];
                break;
            case EventTypePostPractice:
                [retval setObject:kEventTypePostPractice forKey:kEventType];
                break;
            case EventTypeFeedbackLesson:
                [retval setObject:kEventTypeFeedbackLesson forKey:kEventType];
                break;
            case EventTypeReplyPractice:
                [retval setObject:kEventTypeReplyPractice forKey:kEventType];
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
