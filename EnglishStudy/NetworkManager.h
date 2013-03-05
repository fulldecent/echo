//
//  LessonManager.h
//  EnglishStudy
//
//  Created by Will Entriken on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lesson.h"
#import "Word.h"
#import "Profile.h"

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedNetworkManager;

- (void)updateServerVersionForLessons:(NSArray *)lessons
                   onCompletion:(void(^)())block;
- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progress;
- (void)downloadWordWithID:(NSInteger)wordID
              withProgress:(void(^)(Word *PGword, NSNumber *PGprogress))progressBlock
                 onFailure:(void(^)())failureBlock;
- (void)uploadWord:(Word *)word withFilesAtPath:(NSString *)filePath inReplyToWord:(Word *)practiceWord
      withProgress:(void(^)(NSNumber *PGprogress))progressBlock
         onFailure:(void(^)())failureBlock;

enum NetworkManagerFlagReason {
    NetworkManagerFlagReasonInappropriateTitle,
    NetworkManagerFlagReasonInaccurateContent,
    NetworkManagerFlagReasonPoorQuality
};

- (void)flagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)reason
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)likeLesson:(Lesson *)lesson withState:(NSNumber *)like
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)sendLesson:(Lesson *)lesson authorAMessage:(NSString *)message
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)deleteLesson:(Lesson *)lesson
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;

- (void)setMyUsername:(NSString *)username
            onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure __attribute__((deprecated));
- (void)setMyPhoto:(UIImage *)photo
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure __attribute__((deprecated));
- (void)syncProfile:(Profile *)profile
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure; // NEED TO POSSIBLE SAVE UPDATED NAME TO PROFILE
- (NSArray *)recommendedLessons;

- (void)lessonsWithSearch:(NSString *)searchString languageTag:(NSString *)tag return:(void(^)(NSArray *retLessons))returnBlock;

@end
