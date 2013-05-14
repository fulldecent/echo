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

/* HIGHER ORDER FUNCTIONS */

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progress;
- (NSArray *)recommendedLessons;


/*
OLD CODE

- (void)updateServerVersionsInLessonSet:(LessonSet *)lessonSet
           andSeeWhatsNewWithCompletion:(void(^)(NSNumber *newLessonCount, NSNumber *unreadMessageCount))completion;
- (void)downloadWordWithID:(NSInteger)wordID
              withProgress:(void(^)(Word *PGword, NSNumber *PGprogress))progressBlock
                 onFailure:(void(^)())failureBlock;
- (void)uploadWord:(Word *)word withFilesAtPath:(NSString *)filePath inReplyToWord:(Word *)practiceWord
      withProgress:(void(^)(NSNumber *PGprogress))progressBlock
         onFailure:(void(^)())failureBlock;

- (void)flagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)reason
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)likeLesson:(Lesson *)lesson withState:(NSNumber *)like
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)sendLesson:(Lesson *)lesson authorAMessage:(NSString *)message
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)deleteLesson:(Lesson *)lesson
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)syncCurrentUserProfileOnSuccess:(void (^)())success onFailure:(void (^)(NSError *))failure; // NEED TO POSSIBLE SAVE UPDATED NAME TO PROFILE

- (void)texmarkEventWithIDAsRead:(NSNumber *)eventID onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)lessonsWithSearch:(NSString *)searchString languageTag:(NSString *)tag return:(void(^)(NSArray *retLessons))returnBlock;

*/
+ (void)hudFlashError:(NSError *)error;

@end
