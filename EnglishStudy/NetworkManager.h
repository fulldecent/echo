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

@interface NetworkManager : NSObject

+ (NetworkManager *)sharedNetworkManager;

- (void)whichLessonsAreStale:(NSArray *)lessons
                   withBlock:(void(^)(NSArray *lessons))block;
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
            onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)setMyPhoto:(UIImage *)photo
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;

@end
