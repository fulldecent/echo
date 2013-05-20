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
#import "Word.h"
#import "Profile.h"

enum NetworkManagerFlagReason {
    NetworkManagerFlagReasonInappropriateTitle,
    NetworkManagerFlagReasonInaccurateContent,
    NetworkManagerFlagReasonPoorQuality
};

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedNetworkManager;

- (void)getAudioWithID:(NSNumber *)audioID
withProgress:(void(^)(NSData *audio, NSNumber *progress))progressBlock
onFailure:(void(^)(NSError *error))failureBlock;

- (void)deleteLessonWithID:(NSNumber *)lessonID
onSuccess:(void(^)())successBlock
onFailure:(void(^)(NSError *error))failureBlock;

- (void)getLessonWithID:(NSNumber *)lessonID asPreviewOnly:(BOOL)preview
onSuccess:(void(^)(Lesson *lesson))successBlock
onFailure:(void(^)(NSError *error))failureBlock;

- (void)searchLessonsWithLangTag:(NSString *)langTag andSearhText:(NSString *)searchText
                       onSuccess:(void(^)(NSArray *lessonPreviews))successBlock
                       onFailure:(void(^)(NSError *error))failureBlock;

- (void)postLesson:(Lesson *)lesson
         onSuccess:(void(^)(NSNumber *newLessonID, NSNumber *newServerVersion, NSArray *neededWordAndFileCodes))successBlock
         onFailure:(void(^)(NSError *error))failureBlock;

- (void)putTranslation:(Lesson *)translation asLangTag:(NSString *)langTag versionOfLessonWithID:(NSNumber *)id
             onSuccess:(void(^)(NSNumber *translationLessonID, NSNumber *translationVersion))successBlock
             onFailure:(void(^)(NSError *error))failureBlock;

- (void)putAudioFileAtPath:(NSString *)filePath forLesson:(Lesson *)lesson withWord:(Word *)word usingCode:(NSString *)code
              withProgress:(void(^)(NSNumber *progress))progressBlock
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

- (void)doLikeLesson:(Lesson *)lesson
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock;

- (void)doUnlikeLesson:(Lesson *)lesson
             onSuccess:(void(^)())successBlock
             onFailure:(void(^)(NSError *error))failureBlock;

- (void)doFlagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)flagReason
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock;

- (void)getWordWithID:(NSNumber *)wordID
onSuccess:(void(^)(Word *word))successBlock
onFailure:(void(^)(NSError *error))failureBlock;

- (void)deleteWordWithID:(NSNumber *)wordID
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

/* HELPER FUNCTIONS */

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progress;
- (NSArray *)recommendedLessons;
+ (void)hudFlashError:(NSError *)error;

@end
