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
@property (strong, nonatomic) NSMutableSet *staleLessons; // Lesson *
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
    lessonSet.staleLessons = [[NSMutableSet alloc] init];
    
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

- (void)markStaleLessonsWithCallback:(void (^)())block // Stale lessons should not be opened while syncing
{
    [self.staleLessons removeAllObjects];
    NSMutableArray *lessonsToCheck = [[NSMutableArray alloc] init];
    for (Lesson *lesson in self.lessons) {
        if (lesson.isEditable && !lesson.isShared)
            continue;
        else if (lesson.isNewerThanServer || lesson.isOlderThanServer)
            [self.staleLessons addObject:lesson];
        else
            [lessonsToCheck addObject:lesson];
    }
    if ([lessonsToCheck count] == 0) {
        if (block)
            block();
        return;
    }
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager whichLessonsAreStale:lessonsToCheck withBlock:^(NSArray *staleLessons) {
#warning FOR V1.1 SET EACH LESSON SERVER VERSION HERE
        [self.staleLessons addObjectsFromArray:staleLessons];
        if (block)
            block();
    }];
}

- (void)syncStaleLessonsWithProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress // Syncs the ones that are stale
{
    for (Lesson *lesson in [self.staleLessons allObjects]) {
        [self.lessonTransferProgress setObject:[NSNumber numberWithInt:0] forKey:[NSValue valueWithNonretainedObject:lesson]];
        if (progress)
            progress(lesson, [NSNumber numberWithInt:0]);
    }
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager syncLessons:[self.staleLessons allObjects]
                   withProgress:^(Lesson *NMlesson, NSNumber *NMprogress)
     {
         [self.lessonTransferProgress setObject:NMprogress forKey:[NSValue valueWithNonretainedObject:NMlesson]];
         [self writeToDisk];
         if ([NMprogress isEqualToNumber:[NSNumber numberWithInt:1]]) {
             NSLog(@"lessonSetGotProgress: %@", NMprogress);
             [self.lessonTransferProgress removeObjectForKey:[NSValue valueWithNonretainedObject:NMlesson]];
             [self.staleLessons removeObject:NMlesson];
         }
         if (progress)
             progress(NMlesson, NMprogress);
     }];
}

- (void)syncLesson:(Lesson *)lesson withProgress:(void (^)(Lesson *lesson, NSNumber *progress))progress // Syncs the ones that are stale
{
    [self.lessonTransferProgress setObject:[NSNumber numberWithInt:0] forKey:[NSValue valueWithNonretainedObject:lesson]];
    if (progress)
        progress(lesson, [NSNumber numberWithInt:0]);
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];  
    [networkManager syncLessons:[NSArray arrayWithObject:lesson]
                   withProgress:^(Lesson *NMlesson, NSNumber *NMprogress)
     {
         [self.lessonTransferProgress setObject:NMprogress forKey:[NSValue valueWithNonretainedObject:NMlesson]];
         if ([NMprogress floatValue] < 1.0)
             [self.staleLessons addObject:NMlesson];
         if ([NMprogress isEqualToNumber:[NSNumber numberWithInt:1]]) {
             [self.lessonTransferProgress removeObjectForKey:[NSValue valueWithNonretainedObject:NMlesson]];
             [self writeToDisk];
             [self.staleLessons removeObject:NMlesson];
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
    NSString *lessonPath = lesson.filePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager fileExistsAtPath:lessonPath]) {
        if ([fileManager removeItemAtPath:lessonPath error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", lessonPath, error);
        }
    }
    
    // Remove data
    [self.staleLessons removeObject:lesson];
    [self.lessonTransferProgress removeObjectForKey:lesson];
    [self.lessons removeObject:lesson];
    [self writeToDisk];
}

- (void)deleteLessonAndStopSharing:(Lesson *)lesson
                         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager deleteLesson:lesson onSuccess:^
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

@end
