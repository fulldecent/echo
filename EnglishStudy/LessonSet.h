//
//  LessonSet.h
//  EnglishStudy
//
//  Created by Will Entriken on 7/24/12.
//
//

#import <Foundation/Foundation.h>
#import "Lesson.h"

@class LessonSet;

@protocol LessonSetDelegate

@optional
- (void)lessonSet:(LessonSet *)lessonSet gettingLesson:(Lesson *)lesson withProgress:(NSNumber *)percentComplete;
- (void)lessonSet:(LessonSet *)lessonSet gettingLessonDidFail:(Lesson *)lesson;

@end

@interface LessonSet : NSObject

@property (readonly, strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableArray *lessons;
@property (weak, nonatomic) id <LessonSetDelegate> delegate;

+ (LessonSet *)lessonSetWithName:(NSString *)name;
- (void)writeToDisk;
- (void)markStaleLessonsWithCallback:(void (^)())block;
- (void)syncStaleLessonsWithProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress; // Lessons should not be opened while syncing
- (void)syncLesson:(Lesson *)lesson withProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress; // Lessons should not be opened while syncing

- (NSNumber *)transferProgressForLesson:(Lesson *)lesson; // nil or 0.0 to 1.0
- (void)deleteLesson:(Lesson *)lesson;
- (void)deleteLessonAndStopSharing:(Lesson *)lesson
                         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)addOrUpdateLesson:(Lesson *)lesson;
- (NSUInteger)countOfLessonsNeedingSync;

@end
