//
//  LessonManager.m
//  EnglishStudy
//
//  Created by Will Entriken on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetworkManager.h"
#import "MBProgressHUD.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "Audio.h"
#import "NSData+Base64.h"

@interface NetworkManager() <MBProgressHUDDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) AFHTTPRequestOperationManager *requestManager;
@property (strong, nonatomic) NSArray *recommendedLessonsTmp;
@end

@implementation NetworkManager
@synthesize hud = _hud;
@synthesize requestManager = _requestManager;
@synthesize recommendedLessonsTmp = _recommendedLessonsTmp;

+ (NetworkManager *)sharedNetworkManager
{
    static NetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NetworkManager alloc] init];
    });
    return sharedInstance;
}

- (AFHTTPRequestOperationManager *)requestManager
{
    if (!_requestManager) {
        Profile *me = [Profile currentUserProfile];
        _requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:SERVER_ECHO_API_URL]];
        AFHTTPRequestSerializer *authenticateRequests = [AFJSONRequestSerializer serializer];
        [authenticateRequests setAuthorizationHeaderFieldWithUsername:@"xxx" password:me.usercode];
        _requestManager.requestSerializer = authenticateRequests;
    }
    return _requestManager;
}

// V2.0 API ///////////////////////////////////////////////////////

 //      GET     audio/200.caf
 //      DELETE  lessons/172[.json]
 //      GET     lessons/175.json[?preview=yes]
 //      GET     lessons/fr/[?search=bonjour]
 //      POST    lessons/
 //      PUT     lessons/175/translations/fr
 //      PUT     lessons/LESSONCODE/words/WORDCODE/files/FILECODE[.m4a]
 //      GET     users/172.png
 //      POST    users/
 //      GET     users/me/updates?lastLessonSeen=172&lastMessageSeen=229&lessonIDs[]=170&lessonIDs=171&lessonTimestamps[]=1635666&...
 //      PUT     users/me/flagsLessons/175
 //      GET     words/166.json
 //      DELETE  words/[practice/]166[.json]
 //      POST    words/practice/
 //      POST    words/practice/225/replies/
 //      DELETE  events/125[.json]
 //      POST    events/feedbackLesson/125/

 // NOT SURE HOW TO IMPLEMENT THESE
 //      GET     events/eventsTargetingMe/
 //      GET     events/eventsIMayBeInterestedIn/[?some type of query here, probably just paging]
 //      GET     users/172.json


- (void)deleteLessonWithID:(NSNumber *)lessonID
                 onSuccess:(void(^)())successBlock
                 onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"lessons/%d", lessonID.intValue];
    AFHTTPRequestOperation *request = [self.requestManager DELETE:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)getLessonWithID:(NSNumber *)lessonID asPreviewOnly:(BOOL)preview
              onSuccess:(void(^)(Lesson *lesson, NSNumber *modifiedTime))successBlock
              onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath;
    if (preview)
        relativePath = [NSString stringWithFormat:@"lessons/%@.json?preview=yes", lessonID];
    else
        relativePath = [NSString stringWithFormat:@"lessons/%@.json", lessonID];
    AFHTTPRequestOperation *request = [self.requestManager GET:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        Lesson *lesson = [Lesson lessonWithDictionary:responseObject];
        if (successBlock)
            successBlock(lesson, [responseObject objectForKey:@"updated"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)searchLessonsWithLangTag:(NSString *)langTag andSearhText:(NSString *)searchText
                       onSuccess:(void(^)(NSArray *lessonPreviews))successBlock
                       onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"lessons/%@/?search=%@", langTag, searchText];
    AFHTTPRequestOperation *request = [self.requestManager GET:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableArray *lessons = [NSMutableArray array];
        for (id item in (NSArray *)responseObject) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:item options:nil error:nil];
            [lessons addObject:[Lesson lessonWithJSON:data]];
        }
        if (successBlock)
            successBlock(lessons);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)postLesson:(Lesson *)lesson
         onSuccess:(void(^)(NSNumber *newLessonID, NSNumber *newServerVersion, NSArray *neededWordAndFileCodes))successBlock
         onFailure:(void(^)(NSError *error))failureBlock
{
    AFHTTPRequestOperation *request = [self.requestManager POST:@"lessons/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock([responseObject objectForKey:@"lessonID"],
                         [responseObject objectForKey:@"updated"],
                         [responseObject objectForKey:@"neededFiles"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)putTranslation:(Lesson *)translation asLangTag:(NSString *)langTag versionOfLessonWithID:(NSNumber *)lessonID
             onSuccess:(void(^)(NSNumber *translationLessonID, NSNumber *translationVersion))successBlock
             onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"lessons/%d/translations/%@",
                              lessonID.intValue,
                              langTag];
    AFHTTPRequestOperation *request = [self.requestManager PUT:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock([responseObject objectForKey:@"lessonID"],
                         [responseObject objectForKey:@"updated"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)putAudioFileAtPath:(NSString *)filePath forLesson:(Lesson *)lesson withWord:(Word *)word usingCode:(NSString *)code
              withProgress:(void(^)(NSNumber *progress))progressBlock
                 onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"lessons/%@/words/%@/files/%@.caf", lesson.lessonCode, word.wordCode, code];
    AFHTTPRequestOperation *request = [self.requestManager PUT:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (progressBlock)
            progressBlock([NSNumber numberWithInt:1]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request setUploadProgressBlock:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        if (totalBytesExpectedToWrite > 0) {
            if (progressBlock)
                progressBlock([NSNumber numberWithFloat:(float)totalBytesWritten / totalBytesExpectedToWrite]);
        }
    }];
    [request start];
}

- (NSURL *)photoURLForUserWithID:(NSNumber *)userID
{
    NSString *relativeURL = [NSString stringWithFormat:@"users/%@.png", userID];
    return [NSURL URLWithString:relativeURL relativeToURL:[NSURL URLWithString:SERVER_ECHO_API_URL]];
}

- (void)postUserProfile:(Profile *)profile
              onSuccess:(void(^)(NSString *username, NSNumber *userID, NSArray *recommendedLessons))successBlock
              onFailure:(void(^)(NSError *error))failureBlock
{
    NSDictionary *JSONDict = [NSJSONSerialization JSONObjectWithData:[[Profile currentUserProfile] JSON] options:nil error:nil];
    
    AFHTTPRequestOperation *request = [self.requestManager POST:@"users" parameters:JSONDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *username = [(NSDictionary *)responseObject objectForKey:@"username"];
        NSNumber *userID = [(NSDictionary *)responseObject objectForKey:@"userID"];
        NSMutableArray *recommendedLessons = [[NSMutableArray alloc] init];
        for (id lessonJSONDecoded in [(NSDictionary *)responseObject objectForKey:@"recommendedLessons"]) {
            NSData *lessonJSON = [NSJSONSerialization dataWithJSONObject:lessonJSONDecoded options:0 error:nil];
            [recommendedLessons addObject:[Lesson lessonWithJSON:lessonJSON]];
        }
        if (successBlock)
            successBlock(username, userID, recommendedLessons);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)getUpdatesForLessons:(NSArray *)lessons newLessonsSinceID:(NSNumber *)lessonID messagesSinceID:(NSNumber *)messageID
                   onSuccess:(void(^)(NSDictionary *lessonsIDsWithNewServerVersions,
                                      NSNumber *numNewLessons,
                                      NSNumber *numNewMessages))successBlock
                   onFailure:(void(^)(NSError *error))failureBlock
{
    NSMutableArray *lessonIDsToCheck = [[NSMutableArray alloc] init];
    NSMutableArray *lessonTimestampsToCheck = [[NSMutableArray alloc] init];
    for (Lesson *lesson in lessons) {
        if (!lesson.lessonID)
            continue;
        [lessonIDsToCheck addObject:lesson.lessonID];
        if (lesson.serverTimeOfLastCompletedSync)
            [lessonTimestampsToCheck addObject:lesson.serverTimeOfLastCompletedSync];
        else
            [lessonTimestampsToCheck addObject:[NSNumber numberWithInt:0]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    [requestParams setObject:lessonIDsToCheck forKey:@"lessonIDs"];
    [requestParams setObject:lessonTimestampsToCheck forKey:@"lessonTimestamps"];
    if ([defaults objectForKey:@"lastLessonSeen"])
        [requestParams setObject:[defaults objectForKey:@"lastLessonSeen"] forKey:@"lastLessonSeen"];
    if ([defaults objectForKey:@"lastMessageSeen"])
        [requestParams setObject:[defaults objectForKey:@"lastMessageSeen"] forKey:@"lastMessageSeen"];
    NSString *relativePath = @"users/me/updates";
    AFHTTPRequestOperation *request = [self.requestManager GET:relativePath parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock([responseObject objectForKey:@"updatedLessons"],
                         [responseObject objectForKey:@"newLessons"],
                         [responseObject objectForKey:@"unreadMessages"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)doFlagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)flagReason
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"users/me/flagsLessons/%d", lesson.lessonID.intValue];
    NSString *flagString = [NSString stringWithFormat:@"%d", flagReason];
    AFHTTPRequestOperation *request = [self.requestManager PUT:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request setInputStream:[NSInputStream inputStreamWithData:[flagString dataUsingEncoding:NSUTF8StringEncoding]]];
    [request start];
}

- (void)getWordWithID:(NSNumber *)wordID
            onSuccess:(void(^)(Word *word))successBlock
            onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"words/%@.json", wordID];
    AFHTTPRequestOperation *request = [self.requestManager GET:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:nil error:nil];
        Word *word = [Word wordWithJSON:data];
        if (successBlock)
            successBlock(word);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)postWord:(Word *)word AsPracticeWithFilesInPath:(NSString *)filePath
    withProgress:(void(^)(NSNumber *progress))progressBlock
       onFailure:(void(^)(NSError *error))failureBlock
{
    AFHTTPRequestOperation *request = [self.requestManager POST:@"words/practice/" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[word JSON] name:@"word"];
        int fileNum = 0;
        for (Audio *file in word.files) {
            fileNum++;
            NSString *fileName = [NSString stringWithFormat:@"file%d", fileNum];
            NSData *fileData = [NSData dataWithContentsOfFile:[file filePath]];
            [formData appendPartWithFileData:fileData name:fileName fileName:fileName mimeType:@"audio/mp4a-latm"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (progressBlock)
            progressBlock([NSNumber numberWithInt:1]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead > 0) {
            if (progressBlock)
                progressBlock([NSNumber numberWithFloat:(float)totalBytesRead / totalBytesExpectedToRead]);
        }
    }];
    [request start];
}

- (void)postWord:(Word *)word withFilesInPath:(NSString *)filePath asReplyToWordWithID:(NSNumber *)wordID
    withProgress:(void(^)(NSNumber *progress))progressBlock
       onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"words/practice/%@/replies/", wordID];
    AFHTTPRequestOperation *request = [self.requestManager POST:relativePath parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[word JSON] name:@"word"];
        int fileNum = 0;
        for (Audio *file in word.files) {
            fileNum++;
            NSString *fileName = [NSString stringWithFormat:@"file%d", fileNum];
            NSData *fileData = [NSData dataWithContentsOfFile:[file filePath]];
            [formData appendPartWithFileData:fileData name:fileName fileName:fileName mimeType:@"audio/mp4a-latm"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (progressBlock)
            progressBlock([NSNumber numberWithInt:1]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead > 0) {
            if (progressBlock)
                progressBlock([NSNumber numberWithFloat:(float)totalBytesRead / totalBytesExpectedToRead]);
        }
    }];
    [request start];
}

- (void)deleteEventWithID:(NSNumber *)eventID
                onSuccess:(void(^)())successBlock
                onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"events/%@", eventID];
    AFHTTPRequestOperation *request = [self.requestManager DELETE:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)postFeedback:(NSString *)feedback toAuthorOfLessonWithID:(NSNumber *)lessonID
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"events/feedbackLesson/%d/", lessonID.intValue];
    AFHTTPRequestOperation *request = [self.requestManager POST:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}

- (void)getEventsTargetingMeOnSuccess:(void(^)(NSArray *events))successBlock
                            onFailure:(void(^)(NSError *error))failureBlock
{
    AFHTTPRequestOperation *request = [self.requestManager GET:@"events/eventsTargetingMe/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (successBlock)
            successBlock(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request start];
}


#pragma mark - Helper functions /////////////////////////////////////////////////

- (void)pullAudio:(Audio *)audio
     withProgress:(void(^)(NSNumber *progress))progressBlock
        onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"audio/%@.caf", [audio fileID]];
    AFHTTPRequestOperation *request = [self.requestManager GET:relativePath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (progressBlock)
            progressBlock([NSNumber numberWithInt:1]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failureBlock)
            failureBlock(error);
    }];
    [request setDownloadProgressBlock:^(NSUInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead > 0) {
            if (progressBlock)
                progressBlock([NSNumber numberWithFloat:(float)totalBytesRead / totalBytesExpectedToRead]);
        }
    }];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dirname = [audio.filePath stringByDeletingLastPathComponent];
    [fileManager createDirectoryAtPath:dirname withIntermediateDirectories:YES attributes:nil error:nil];
    request.outputStream = [NSOutputStream outputStreamToFileAtPath:audio.filePath append:NO];
    [request start];
}

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
{
    for (Lesson *lessonToSync in lessons) {
        // Which direction is this motherfucter syncing?
        if (lessonToSync.localChangesSinceLastSync)
            [self pushLessonWithFiles:lessonToSync withProgress:progressBlock onFailure:nil];
        else if (lessonToSync.remoteChangesSinceLastSync || [[lessonToSync listOfMissingFiles] count])
            [self pullLessonWithFiles:lessonToSync withProgress:progressBlock onFailure:nil];
        else {
            NSLog(@"No which way for this lesson to sync: %@", lessonToSync);
            if (progressBlock)
                progressBlock(lessonToSync, [NSNumber numberWithInt:1]);
        }
    }
}

- (void)pullLessonWithFiles:(Lesson *)lessonToSync
         withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
            onFailure:(void(^)(NSError *error))failureBlock
{
    NSLog(@"WANT TO PULL LESSON: %@", [lessonToSync lessonID]);
    NSLog(@"%@",[NSThread callStackSymbols]);

    [self getLessonWithID:lessonToSync.lessonID asPreviewOnly:NO onSuccess:^(Lesson *retreivedLesson, NSNumber *modifiedTime)
     {
         NSLog(@"PULLING LESSON: %@", [lessonToSync lessonID]);
         NSLog(@"%@",[NSThread callStackSymbols]);
         
         [lessonToSync setToLesson:retreivedLesson];
         NSMutableArray *neededAudios = [[NSMutableArray alloc] init];
         for (NSDictionary *audioAndWord in [lessonToSync listOfMissingFiles])
             [neededAudios addObject:[audioAndWord objectForKey:@"audio"]];         
         __block NSNumber *lessonProgress = [NSNumber numberWithInt:1];
         __block NSNumber *totalLessonProgress = @([neededAudios count]+1);
         
         if ([neededAudios count] == 0) {
             lessonToSync.serverTimeOfLastCompletedSync = modifiedTime;
             lessonToSync.remoteChangesSinceLastSync = NO;
         }
         if (progressBlock)
             progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);
         
         NSMutableDictionary *progressPerAudioFile = [NSMutableDictionary dictionary];
         NSLog(@"NEEDED AUDIOS: %@", neededAudios);
         
         for (Audio *file in neededAudios) {
//             NSLog(@"PULLING AUDIO: %@", [file fileID]);
             [progressPerAudioFile setObject:[NSNumber numberWithFloat:0] forKey:[file fileID]];
             [self pullAudio:file withProgress:^(NSNumber *fileProgress) {
//                 NSLog(@"FILE PROGRESS: %@ %@", [file fileID], fileProgress);
                 [progressPerAudioFile setObject:fileProgress forKey:[file fileID]];
                 NSNumber *filesProgress = [[progressPerAudioFile allValues] valueForKeyPath:@"@sum.self"];
                 lessonProgress = [NSNumber numberWithFloat:[filesProgress floatValue] + 1];
                 
                 if ([fileProgress isEqualToNumber:[NSNumber numberWithInt:1]]) {
                     if ([lessonProgress isEqualToNumber:totalLessonProgress])
                         lessonToSync.serverTimeOfLastCompletedSync = modifiedTime;
                     if (progressBlock)
                         progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);
                 }
             } onFailure:^(NSError *error) {
             }];
         }
     } onFailure:^(NSError *error) {
         if (failureBlock)
             failureBlock(error);
     }];
}

// Side effect: will set the lesson ID if it is null and will update serverversion
- (void)pushLessonWithFiles:(Lesson *)lessonToSync
         withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
            onFailure:(void(^)(NSError *error))failureBlock
{
    [self postLesson:lessonToSync onSuccess:^(NSNumber *newLessonID, NSNumber *newServerVersion, NSArray *neededWordAndFileCodes)
     {
         __block NSNumber *lessonProgress = @(1);
         __block NSNumber *totalLessonProgress = @([neededWordAndFileCodes count]+1);
         lessonToSync.lessonID = newLessonID;
         if ([neededWordAndFileCodes count] == 0) {
             lessonToSync.serverTimeOfLastCompletedSync = newServerVersion;
             lessonToSync.localChangesSinceLastSync = NO;
         }
         if (progressBlock)
             progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);

         for (NSDictionary *wordAndFileCode in neededWordAndFileCodes) {
             Word *word = [lessonToSync wordWithCode:[wordAndFileCode objectForKey:@"wordCode"]];
             Audio *file = [word fileWithCode:[wordAndFileCode objectForKey:@"fileCode"]];

             [self putAudioFileAtPath:file.filePath
                            forLesson:lessonToSync
                             withWord:word
                            usingCode:file.fileCode
                         withProgress:^(NSNumber *fileProgress)
              {
                  if ([fileProgress isEqualToNumber:[NSNumber numberWithInt:1]]) {
                      lessonProgress = @([lessonProgress integerValue]+1);
                      if ([lessonProgress isEqualToNumber:totalLessonProgress]) {
                          lessonToSync.serverTimeOfLastCompletedSync = newServerVersion;
                          lessonToSync.localChangesSinceLastSync = NO;
                      }
                      if (progressBlock)
                          progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);
                      //TODO: Could do even more accurate progress reporting if we wanted
                  }
              } onFailure:^(NSError *error)
              {
              }];
         }
     } onFailure:^(NSError *error) {
         if (failureBlock) failureBlock(error);
     }];
}

- (void)getWordWithFiles:(NSNumber *)wordID
             withProgress:(void(^)(Word *word, NSNumber *progress))progress
               onFailure:(void(^)(NSError *error))failureBlock;
{
    [self getWordWithID:wordID onSuccess:^(Word *word)
     {
         NSArray *neededAudios = [word listOfMissingFiles];
         __block NSNumber *wordProgress = [NSNumber numberWithInt:1];
         __block NSNumber *totalWordProgress = @([neededAudios count]+1);
         if (progress)
             progress(word, [NSNumber numberWithFloat:[wordProgress floatValue]/[totalWordProgress floatValue]]);
         
         NSMutableDictionary *progressPerAudioFile = [NSMutableDictionary dictionary];
         
         for (Audio *file in neededAudios) {
             [progressPerAudioFile setObject:[NSNumber numberWithFloat:0] forKey:[file fileID]];

             [self pullAudio:file withProgress:^(NSNumber *fileProgress) {
                 NSLog(@"FILE PROGRESS: %@ %@", [file fileID], fileProgress);
                 [progressPerAudioFile setObject:fileProgress forKey:[file fileID]];
                 NSNumber *filesProgress = [[progressPerAudioFile allValues] valueForKeyPath:@"@sum.self"];
                 wordProgress = [NSNumber numberWithFloat:[filesProgress floatValue] + 1];
                 if (progress)
                     progress(word, [NSNumber numberWithFloat:[wordProgress floatValue]/[totalWordProgress floatValue]]);
             } onFailure:^(NSError *error) {
             }];
         }
     }
              onFailure:^(NSError *error)
     {
         if (failureBlock)
             failureBlock(error);
     }];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - FUCKYOU UI code seperation

+ (void)hudFlashError:(NSError *)error
{
    static MBProgressHUD *sharedHUD;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
        sharedHUD.mode = MBProgressHUDModeCustomView;
    });
    [sharedHUD hide:NO];
    [sharedHUD show:YES];
    UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view.text = error.localizedDescription;
    view.font = sharedHUD.labelFont;
    view.textColor = [UIColor whiteColor];
    view.backgroundColor = [UIColor clearColor];
    [view sizeToFit];
    sharedHUD.customView = view;
    [sharedHUD hide:YES afterDelay:1.2];
}


@end
