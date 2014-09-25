//
//  LessonSet.m
//  EnglishStudy
//
//  Created by Will Entriken on 7/24/12.
//
//

#import "LessonSet.h"
#import "NetworkManager.h"

@interface LessonSet()
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableDictionary *lessonTransferProgress; // NSValue: Lesson *
@end

@implementation LessonSet
@synthesize name = _name;
@synthesize lessons = _lessons;

+ (LessonSet *)lessonSetWithName:(NSString *)name
{
    LessonSet *lessonSet = [[LessonSet alloc] init];
    lessonSet.name = name;
    lessonSet.lessonTransferProgress = [[NSMutableDictionary alloc] init];
    lessonSet.lessons = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *lessonJSON in [defaults objectForKey:[@"lessons-" stringByAppendingString:name]]) {
        Lesson *lesson = [Lesson lessonWithJSON:[lessonJSON dataUsingEncoding:NSUTF8StringEncoding]];
        [lessonSet.lessons addObject:lesson];
    }
    return lessonSet;
}

- (void)writeToDisk
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *savedLessons = [[NSMutableArray alloc] init];
    for (Lesson *lesson in self.lessons) {
        NSString *lessonJSON = [[NSString alloc] initWithData:[lesson JSON] encoding:NSUTF8StringEncoding];
        [savedLessons addObject:lessonJSON];
    }
    [defaults setObject:savedLessons forKey:[@"lessons-" stringByAppendingString:self.name]];
    [defaults synchronize];
}

- (void)syncStaleLessonsWithProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress // Syncs the ones that are stale
{
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    NSMutableArray *staleLessons = [[NSMutableArray alloc] init];
    for (Lesson *lesson in self.lessons) {
        if (lesson.localChangesSinceLastSync || lesson.remoteChangesSinceLastSync) {
            if ([self transferProgressForLesson:lesson])
                continue;            
            [staleLessons addObject:lesson];
            [self.lessonTransferProgress setObject:[NSNumber numberWithInt:0] forKey:[NSValue valueWithNonretainedObject:lesson]];
            if (progress)
                progress(lesson, [NSNumber numberWithInt:0]);
        }
    }
    [networkManager syncLessons:staleLessons
                   withProgress:^(Lesson *NMlesson, NSNumber *NMprogress)
     {
         if ([NMprogress floatValue] < 1.0)
             [self.lessonTransferProgress setObject:NMprogress forKey:[NSValue valueWithNonretainedObject:NMlesson]];
         else {
             [self.lessonTransferProgress removeObjectForKey:[NSValue valueWithNonretainedObject:NMlesson]];
             [self writeToDisk];
         }
         if (progress)
             progress(NMlesson, NMprogress);
     }];
}

- (NSNumber *)transferProgressForLesson:(Lesson *)lesson // nil or 0.0 to 1.0
{
    return [self.lessonTransferProgress objectForKey:[NSValue valueWithNonretainedObject:lesson]];
}

- (void)deleteLesson:(Lesson *)lesson
{
    // Remove files
    NSURL *lessonURL = lesson.fileURL;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([lessonURL checkResourceIsReachableAndReturnError:nil]) {
        if ([fileManager removeItemAtURL:lessonURL error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", lessonURL, error);
        }
    }
    
    // Remove data
    [self.lessonTransferProgress removeObjectForKey:lesson];
    [self.lessons removeObject:lesson];
    [self writeToDisk];
}

- (void)deleteLessonAndStopSharing:(Lesson *)lesson
                         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager deleteLessonWithID:lesson.lessonID
                             onSuccess:^
     {
         [self deleteLesson:lesson];
         if (success)
             success();
     }
                             onFailure:^(NSError *error)
     {
         if (failure)
             failure(error);
     }];
}

- (void)addOrUpdateLesson:(Lesson *)lesson
{
    if ([self.lessons containsObject:lesson]) {
        [self writeToDisk];
        return;
    } else if ([lesson.lessonID integerValue]) {
        for (int i=0; i<[self.lessons count]; i++) {
            if ([[(Lesson *)[self.lessons objectAtIndex:i] lessonID] isEqualToNumber:lesson.lessonID]) {
                [self.lessons replaceObjectAtIndex:i withObject:lesson];
                [self writeToDisk];
                return;
            }
        }
    }
    [self.lessons addObject:lesson];
    [self writeToDisk];
}

- (void)setRemoteUpdatesForLessonsWithIDs:(NSArray *)newLessonIDs
{
    for (Lesson *lesson in self.lessons)
        if ([newLessonIDs containsObject:lesson.lessonID])
            lesson.remoteChangesSinceLastSync = YES;
    [self writeToDisk];
}

@end
