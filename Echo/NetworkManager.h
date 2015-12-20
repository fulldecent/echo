//
//  LessonManager.h
//  EnglishStudy
//
//  Created by Will Entriken on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LessonSet.h"
#import "Lesson.h"
#import "Profile.h"

#define SERVER_ECHO_API_URL @"https://learnwithecho.com/api/2.0/"

enum NetworkManagerFlagReason {
    NetworkManagerFlagReasonInappropriateTitle,
    NetworkManagerFlagReasonInaccurateContent,
    NetworkManagerFlagReasonPoorQuality
};

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedNetworkManager;

- (void)deleteLessonWithID:(NSNumber *)lessonID
                 onSuccess:(void(^)())successBlock
                 onFailure:(void(^)(NSError *error))failureBlock;

- (void)searchLessonsWithLangTag:(NSString *)langTag andSearhText:(NSString *)searchText
                       onSuccess:(void(^)(NSArray *lessonPreviews))successBlock
                       onFailure:(void(^)(NSError *error))failureBlock;

- (void)putTranslation:(Lesson *)translation asLangTag:(NSString *)langTag versionOfLessonWithID:(NSNumber *)id
             onSuccess:(void(^)(NSNumber *translationLessonID, NSNumber *translationVersion))successBlock
             onFailure:(void(^)(NSError *error))failureBlock;

- (NSURL *)photoURLForUserWithID:(NSNumber *)userID;

- (void)postUserProfile:(Profile *)profile
              onSuccess:(void(^)(NSString *username, NSNumber *userID, NSArray *recommendedLessons))successBlock
              onFailure:(void(^)(NSError *error))failureBlock;

- (void)getUpdatesForLessons:(NSArray *)lessons newLessonsSinceID:(NSNumber *)lessonID messagesSinceID:(NSNumber *)messageID
                   onSuccess:(void(^)(NSDictionary *lessonsIDsWithNewServerVersions,
                                      NSNumber *numNewLessons,
                                      NSNumber *numNewMessages))successBlock
                   onFailure:(void(^)(NSError *error))failureBlock;

- (void)doFlagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)flagReason
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock;

- (void)postWord:(Word *)word AsPracticeWithFilesInPath:(NSString *)filePath
    withProgress:(void(^)(NSNumber *progress))progressBlock
       onFailure:(void(^)(NSError *error))failureBlock;

- (void)postWord:(Word *)word withFilesInPath:(NSString *)filePath asReplyToWordWithID:(NSNumber *)wordID
    withProgress:(void(^)(NSNumber *progress))progressBlock
    onFailure:(void(^)(NSError *error))failureBlock;

- (void)deleteEventWithID:(NSNumber *)eventID
                onSuccess:(void(^)())successBlock
                onFailure:(void(^)(NSError *error))failureBlock;

- (void)postFeedback:(NSString *)feedback toAuthorOfLessonWithID:(NSNumber *)lessonID
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock;

- (void)getEventsTargetingMeOnSuccess:(void(^)(NSArray *events))successBlock
                            onFailure:(void(^)(NSError *error))failureBlock;

- (void)getEventsIMayBeInterestedInOnSuccess:(void(^)(NSArray *events))successBlock
                                   onFailure:(void(^)(NSError *error))failureBlock;


/* HELPER FUNCTIONS */

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progress;
- (void)getWordWithFiles:(NSNumber *)wordID
            withProgress:(void(^)(Word *word, NSNumber *progress))progress
               onFailure:(void(^)(NSError *error))failureBlock;

+ (void)hudFlashError:(NSError *)error;

@end
