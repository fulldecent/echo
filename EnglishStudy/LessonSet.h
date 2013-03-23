//
//  LessonSet.h
//  EnglishStudy
//
//  Created by Will Entriken on 7/24/12.
//
//

#import <Foundation/Foundation.h>
#import "Lesson.h"

@interface LessonSet : NSObject
@property (readonly, strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableArray *lessons;

+ (LessonSet *)lessonSetWithName:(NSString *)name;
- (void)writeToDisk;
- (void)syncLesson:(Lesson *)lesson withProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress; // Lessons should not be opened while syncing

- (NSNumber *)transferProgressForLesson:(Lesson *)lesson; // nil or 0.0 to 1.0
- (void)deleteLesson:(Lesson *)lesson;
- (void)deleteLessonAndStopSharing:(Lesson *)lesson
                         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure;
- (void)addOrUpdateLesson:(Lesson *)lesson;

@end
