//
//  LessonManager.m
//  EnglishStudy
//
//  Created by Will Entriken on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetworkManager.h"
#import "MBProgressHUD.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"

#define SERVER_ECHO_API_URL @"http://learnwithecho.com/api/1.0/"

@interface NetworkManager() <MBProgressHUDDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) AFHTTPClient *HTTPclient;
@property (strong, nonatomic) NSArray *recommendedLessonsTmp;
@end

@implementation NetworkManager
@synthesize hud = _hud;
@synthesize HTTPclient = _HTTPclient;
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

- (id)init
{
    self = [super init];
    self.HTTPclient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:SERVER_ECHO_API_URL]];
    [self.HTTPclient setParameterEncoding:AFFormURLParameterEncoding];
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
//    self.HTTPclient.parameterEncoding = AFJSONParameterEncoding;
//	[self.HTTPclient setDefaultHeader:@"Accept" value:@"application/json"];
    [self.HTTPclient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    return self;
}

- (void)updateServerVersionsInLessonSet:(LessonSet *)lessonSet
           andSeeWhatsNewWithCompletion:(void(^)(NSNumber *newLessonCount, NSNumber *unreadMessageCount))completion
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSMutableArray *lessonIDsToCheck = [[NSMutableArray alloc] init];
    NSMutableArray *lessonIDTimestamps = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (Lesson *lesson in lessonSet.lessons) {
        if ([lesson.lessonID integerValue] != 0) { // Didn't finish uploading
            [lessonIDsToCheck addObject:lesson.lessonID];
            if (lesson.version)
                [lessonIDTimestamps addObject:lesson.version];
            else
                [lessonIDTimestamps addObject:[NSNumber numberWithInt:0]];
        }
    }

    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/whatsNew", deviceUUID];
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:relativeRequestPath
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                    {
                                        NSData *lessonIDsJSON = [NSJSONSerialization dataWithJSONObject:lessonIDsToCheck options:0 error:nil];
                                        NSData *timestampsJSON = [NSJSONSerialization dataWithJSONObject:lessonIDTimestamps options:0 error:nil];
                                        if ([defaults objectForKey:@"lastLessonSeen"])
                                            [formData appendPartWithFormData:[[(NSNumber *)[defaults objectForKey:@"lastLessonSeen"] stringValue] dataUsingEncoding:NSUTF8StringEncoding] name:@"lastLessonSeen"];
                                        if ([defaults objectForKey:@"lastMessageSeen"])
                                            [formData appendPartWithFormData:[[(NSNumber *)[defaults objectForKey:@"lastMessageSeen"] stringValue] dataUsingEncoding:NSUTF8StringEncoding] name:@"lastLessonSeen"];
                                        [formData appendPartWithFormData:lessonIDsJSON name:@"lessonIDs"];
                                        [formData appendPartWithFormData:timestampsJSON name:@"timestamps"];
                                    }];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          for (NSString *lessonIDStr in [JSON objectForKey:@"updatedLessons"]) {
                                              NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                                              [f setNumberStyle:NSNumberFormatterDecimalStyle];
                                              NSNumber *lessonID = [f numberFromString:lessonIDStr];
                                              
                                              for (Lesson *lesson in lessonSet.lessons) {
                                                  if ([lesson.lessonID isEqualToNumber:lessonID]) // a little weird
                                                      lesson.serverVersion = [JSON objectForKey:lessonIDStr];
                                              }
                                          }
                                          if (completion)
                                              completion([JSON objectForKey:@"newLessons"], [JSON objectForKey:@"unreadMessages"]);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          NSLog(@"updateServerVersionForLessons failed:%@", [error localizedDescription]);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)updateServerVersionForLessons:(NSArray *)lessons
                   onCompletion:(void(^)())block
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSMutableArray *lessonIDsToCheck = [[NSMutableArray alloc] init];
    NSMutableArray *lessonIDTimestamps = [[NSMutableArray alloc] init];

    for (Lesson *lesson in lessons) {
        if ([lesson.lessonID integerValue] != 0) { // Didn't finish uploading
            [lessonIDsToCheck addObject:lesson.lessonID];
            [lessonIDTimestamps addObject:lesson.version];
        }
    }

    if ([lessonIDsToCheck count]) {
        NSString *relativeRequestPath = [@"lessons/whichOnesAreStale?userCode=" stringByAppendingString:deviceUUID] ;
        NSData *lessonIDsJSON = [NSJSONSerialization dataWithJSONObject:lessonIDsToCheck options:0 error:nil];
        NSData *timestampsJSON = [NSJSONSerialization dataWithJSONObject:lessonIDTimestamps options:0 error:nil];
        
        NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                                  path:relativeRequestPath
                                                                            parameters:nil
                                                             constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                        {
                                            [formData appendPartWithFormData:lessonIDsJSON name:@"lessonIDs"];
                                            [formData appendPartWithFormData:timestampsJSON name:@"timestamps"];
                                        }
                                        ];
        AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                          {
                                              for (NSString *lessonIDStr in JSON) {
                                                  NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                                                  [f setNumberStyle:NSNumberFormatterDecimalStyle];
                                                  NSNumber *lessonID = [f numberFromString:lessonIDStr];
                                                  
                                                  for (Lesson *lesson in lessons) {
                                                      if ([lesson.lessonID isEqualToNumber:lessonID]) // a little weird
                                                          lesson.serverVersion = [JSON objectForKey:lessonIDStr];
                                                  }
                                              }
                                              if (block)
                                                  block();
                                          }
                                                                                         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                          {
                                              [self hudFlashError:error];
                                              NSLog(@"updateServerVersionForLessons failed:%@", [error localizedDescription]);
                                              if (block)
                                                  block();
                                          }];
        
        [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
    } else {
        if (block)
            block();
    }
}

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))block
{
#warning FOR V1.1 Use some type of queue here rather than madness
    
    for (Lesson *lessonToSync in lessons) {
        
        // Which direction is this motherfucter syncing?
        if ([[lessonToSync listOfMissingFiles] count] || lessonToSync.isOlderThanServer)
            [self downloadLesson:lessonToSync withProgress:^(Lesson *lesson, NSNumber *progress)
             {
                 if (block)
                     block(lesson, progress);
             }];
        else if (lessonToSync.isEditable && lessonToSync.isNewerThanServer) {
            [self uploadLesson:lessonToSync withProgress:^(Lesson *lesson, NSNumber *lessonID, NSNumber *progress)
            {
                if (![lessonToSync.lessonID isEqualToNumber:lessonID])
                    lesson.lessonID = lessonID;
                if (block)
                    block(lesson, progress);
            }];
        }
        else {
            NSLog(@"No which way for this lesson to sync: %@", lessonToSync);
            if (block)
                block(lessonToSync, [NSNumber numberWithInt:1]);
        }
    }
}

- (void)downloadWordWithID:(NSInteger)wordID
            withProgress:(void(^)(Word *PGword, NSNumber *PGprogress))progressBlock
               onFailure:(void(^)())failureBlock;
{
    __block NSNumber *progress = [NSNumber numberWithInt:0];
    __block NSNumber *totalProgress = [NSNumber numberWithInt:1];
    
    // Transfer parameters
    NSString *relativeRequestPath = [NSString stringWithFormat:@"words/%d.json", wordID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET"
                                                                 path:relativeRequestPath
                                                           parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          __block Word *retreivedWord = [Word wordWithJSON:[NSJSONSerialization dataWithJSONObject:JSON options:0 error:nil]];
                                          NSArray *neededFiles = [retreivedWord listOfMissingFiles];
                                          progress = [NSNumber numberWithInt:1];
                                          totalProgress = [NSNumber numberWithInt:[neededFiles count]+1];
                                          if (progressBlock)
                                              progressBlock(retreivedWord, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);
                                          
                                          for (NSNumber *fileID in neededFiles) {
                                              [self downloadAudioFileID:[fileID integerValue] onSuccess:^(NSString *filePath)
                                               {
                                                   progress = [NSNumber numberWithInt:[progress integerValue]+1];
                                                   if (progressBlock)
                                                       progressBlock(retreivedWord, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);
                                               } onFailure:^(NSError *error) {
                                                   if (failureBlock)
                                                       failureBlock();
                                               } onProgress:nil];
                                          }
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock();
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)uploadWord:(Word *)word withFilesAtPath:(NSString *)filePath inReplyToWord:(Word *)practiceWord
      withProgress:(void(^)(NSNumber *PGprogress))progressBlock
         onFailure:(void(^)())failureBlock
{
    // Transfer parameters and statistics
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    
    // Transfer parameters
    NSString *relativeRequestPath = [NSString stringWithFormat:@"words/%@/reply?userGUID=%@", practiceWord.wordID, deviceUUID];
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:relativeRequestPath
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                    {
                                        [formData appendPartWithFormData:[word JSON] name:@"word"];
                                        int i=1;
                                        for (NSString *file in word.files) {
                                            NSURL *fileURL = [NSURL fileURLWithPath:[filePath stringByAppendingPathComponent:file]];
                                            [formData appendPartWithFileURL:fileURL
                                                                       name:[NSString stringWithFormat:@"file%d", i++]
                                                                      error:nil];
                                        }
                                    }];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (progressBlock)
                                              progressBlock([NSNumber numberWithInt:1]);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock();
                                          [self hudFlashError:error];
                                          NSLog(@"Upload word error:%@", [error localizedDescription]);
                                      }];
    [JSONop setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (progressBlock)
            progressBlock([NSNumber numberWithFloat:totalBytesWritten*1.0/totalBytesExpectedToWrite ]);
    }];
    
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}


// HELPER FUNCTIONS //////////////////////////////////////////////////

- (void)uploadLesson:(Lesson *)lesson
        withProgress:(void(^)(Lesson *lesson, NSNumber *lessonID, NSNumber *progress))block
{
    // Transfer parameters and statistics
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    
    if (block)
        block(lesson, lesson.lessonID, [NSNumber numberWithInt:0]);
    __block NSNumber *progress = [NSNumber numberWithInt:0];
    __block NSNumber *totalProgress = [NSNumber numberWithInt:1];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:lesson.JSON forKey:@"lesson"];
    [params setObject:deviceUUID forKey:@"userCode"];
    [params setObject:lesson.lessonCode forKey:@"lessonCode"];
    
    // Transfer parameters
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:@"lessons"
                                                                        parameters:params
                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {}];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          NSNumber *lessonID = [JSON objectForKey:@"lessonID"];
                                          lesson.lessonID = [JSON objectForKey:@"lessonID"];
                                          lesson.version = [JSON objectForKey:@"updated"];
                                          
                                          progress = [NSNumber numberWithInt:1];
                                          totalProgress = [NSNumber numberWithInt:[[JSON objectForKey:@"neededFiles"] count]+1];
                                          if ([[JSON objectForKey:@"neededFiles"] count] == 0)
                                               lesson.serverVersion = [lesson.version copy];
                                          if (block)
                                              block(lesson, lessonID, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);

                                          for (NSDictionary *neededFile in [JSON objectForKey:@"neededFiles"]) {
                                              NSString *wordCode = [neededFile objectForKey:@"wordCode"];
                                              NSString *fileCode = [neededFile objectForKey:@"fileCode"];
                                              Word *word;
                                              NSNumber *fileNumber;
                                              
                                              for (Word *searchWord in lesson.words) {
                                                  if ([searchWord.wordCode isEqualToString:wordCode]) {
                                                      word = searchWord;
                                                      break;
                                                  }
                                              }
                                              for (int i=0; i<word.files.count; i++) {
                                                  if ([[word.files objectAtIndex:i] isEqualToString:fileCode]) {
                                                      fileNumber = [NSNumber numberWithInt:i];
                                                  }
                                              }
                                              
                                              [self uploadAudioFileNumber:fileNumber inWord:word inLesson:lesson
                                                                onSuccess:^{
                                                                    progress = [NSNumber numberWithInt:[progress intValue]+1];
                                                                    if ([progress isEqualToNumber:totalProgress])
                                                                        lesson.serverVersion = [lesson.version copy];
                                                                    if (block)
                                                                        block(lesson, lessonID, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);
                                                                }
                                                                onFailure:^{
                                                                    NSLog(@"Upload file failure: %d", [fileNumber integerValue]);
                                                                }
                                               ];
                                          }
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          NSLog(@"Upload lesson:%@ withError:%@", lesson.lessonCode, [error localizedDescription]);
                                      }];
    
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)uploadAudioFileNumber:(NSNumber *)fileNumber inWord:(Word *)word inLesson:(Lesson *)lesson
                    onSuccess:(void(^)())onSuccess
                    onFailure:(void(^)())onFailure
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *lessonPath = [documentsPath stringByAppendingPathComponent:lesson.lessonCode];
    NSString *wordPath = [lessonPath stringByAppendingPathComponent:word.wordCode];
    NSString *audioPath = [wordPath stringByAppendingPathComponent:[word.files objectAtIndex:[fileNumber integerValue]]];
    NSData *audioFileData = [NSData dataWithContentsOfFile:audioPath];
    
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/lessons/%@/words/%@/files/%@",
                                     deviceUUID, lesson.lessonCode, word.wordCode, [word.files objectAtIndex:[fileNumber integerValue]]];
    
    //***********************
    
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:relativeRequestPath
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                    {
                                        [formData appendPartWithFileData:audioFileData
                                                                    name:@"file"
                                                                fileName:[word.files objectAtIndex:[fileNumber integerValue]]
                                                                mimeType:@"audio/mp4a-latm"];
                                    }
                                    ];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
    [operation setCompletionBlock:^{
        if (onSuccess)
            onSuccess();
    }];
    
    [self.HTTPclient enqueueHTTPRequestOperation:operation];
}

- (void)downloadLesson:(Lesson *)lesson
          withProgress:(void(^)(Lesson *lesson, NSNumber *progress))block
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    
    __block NSNumber *progress = [NSNumber numberWithInt:0];
    __block NSNumber *totalProgress = [NSNumber numberWithInt:1];

    // Transfer parameters
    NSString *relativeRequestPath = [NSString stringWithFormat:@"lessons/%@.json?userCode=%@", lesson.lessonID, deviceUUID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET"
                                                                 path:relativeRequestPath
                                                           parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          Lesson *retreivedLesson = [Lesson lessonWithJSON:[NSJSONSerialization dataWithJSONObject:JSON
                                                                                                                           options:0 error:nil]];
                                          [lesson setToLesson:retreivedLesson];
                                          lesson.serverVersion = [JSON objectForKey:@"updated"];
                                          [lesson removeStaleFiles];
                                          NSArray *neededFiles = [lesson listOfMissingFiles];
                                          
                                          progress = [NSNumber numberWithInt:1];
                                          totalProgress = [NSNumber numberWithInt:[neededFiles count]+1];
                                          if ([neededFiles count] == 0)
                                              lesson.version = lesson.serverVersion;
                                          if (block)
                                              block(lesson, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);
                                          
                                          for (NSDictionary *dict in neededFiles) {
                                              NSString *saveAs;
                                              if ([dict objectForKey:@"fileCode"])
                                                  saveAs = [dict objectForKey:@"fileCode"];
                                              else
                                                  saveAs = [dict objectForKey:@"fileID"];
                                              [self downloadAudioFileID:[dict objectForKey:@"fileID"]
                                                                 saveAs:saveAs
                                                                 inWord:[dict objectForKey:@"word"]
                                                               inLesson:lesson
                                                              onSuccess:^
                                               {
                                                   progress = [NSNumber numberWithInt:[progress integerValue]+1];
                                                   if ([progress isEqualToNumber:totalProgress])
                                                       lesson.version = lesson.serverVersion;
                                                   if (block)
                                                       block(lesson, [NSNumber numberWithFloat:[progress floatValue]/[totalProgress floatValue]]);
                                               }
                                                              onFailure:^(NSError *error)
                                               {
                                                   [self hudFlashError:error];
                                                   NSLog(@"Error downloading file:%@", [error localizedDescription]);
                                               }];
                                          }
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          NSLog(@"Error downloading lesson:%@", [error localizedDescription]);
                                      }];
                                          
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)downloadAudioFileID:(NSString *)fileID saveAs:(NSString *)saveAs inWord:(Word *)word inLesson:(Lesson *)lesson
                    onSuccess:(void(^)())onSuccess
                    onFailure:(void(^)(NSError *error))onFailure
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    
    NSString *relativeRequestPath;
    NSString *wordPath;
    if ([word.wordCode length] > 0) {
        relativeRequestPath = [NSString stringWithFormat:@"users/%@/lessons/%@/words/%@/files/%@",
                               deviceUUID, lesson.lessonCode, word.wordCode, fileID];
        wordPath = [lesson.filePath stringByAppendingPathComponent:word.wordCode];
    } else {
        relativeRequestPath = [NSString stringWithFormat:@"audio/%@", fileID];
        wordPath = [lesson.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [word.wordID integerValue]]];
    }
    NSString *filePath = [wordPath stringByAppendingPathComponent:saveAs];

    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET"
                                                                 path:relativeRequestPath
                                                           parameters:nil];
    AFHTTPRequestOperation *HTTPop = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [HTTPop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSFileManager *fileManager = [NSFileManager defaultManager];
         if (![fileManager fileExistsAtPath:wordPath])
             [fileManager createDirectoryAtPath:wordPath withIntermediateDirectories:YES attributes:nil error:nil];
         [(NSData *)responseObject writeToFile:filePath atomically:YES];
         if (onSuccess)
             onSuccess();
     }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [self hudFlashError:error];
         NSLog(@"Error downloading file:%@", [error localizedDescription]);
         if (onFailure)
             onFailure(error);
     }];
  
    [self.HTTPclient enqueueHTTPRequestOperation:HTTPop];
}

// Saves to tmp dir
- (void)downloadAudioFileID:(NSInteger)fileID
                  onSuccess:(void(^)(NSString *filePath))onSuccess
                  onFailure:(void(^)(NSError *error))onFailure
                  onProgress:(void(^)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
{
    NSString *tempFilePath;
    NSString *baseName = [NSString stringWithFormat:@"%d", fileID];
    tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:baseName];
    
    NSString *relativeRequestPath = [NSString stringWithFormat:@"audio/%d", fileID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET"
                                                                 path:relativeRequestPath
                                                           parameters:nil];
    AFHTTPRequestOperation *HTTPop = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [HTTPop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if([(NSData *)responseObject writeToFile:tempFilePath atomically:YES])
             onSuccess(tempFilePath);
         else
             onFailure(nil);
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         onFailure(error);
     }];
    
    [HTTPop setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progress)
            progress(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }];
    [self.HTTPclient enqueueHTTPRequestOperation:HTTPop];
}

- (void)flagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)reason
         onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *flagString = [NSString stringWithFormat:@"%d", reason];
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/flag/%@?flag=%@", deviceUUID, lesson.lessonID, flagString];
    
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:relativeRequestPath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failure)
                                              failure(error);
                                          NSLog(@"Flag failed:%@", [error localizedDescription]);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)likeLesson:(Lesson *)lesson withState:(NSNumber *)like onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *likeString = [like boolValue] ? @"yes" : @"no";
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/like/%@?like=%@", deviceUUID, lesson.lessonID, likeString];

    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:relativeRequestPath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failure)
                                              failure(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)sendLesson:(Lesson *)lesson authorAMessage:(NSString *)message onSuccess:(void (^)())success onFailure:(void (^)(NSError *))failure
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/messageLessonAuthor/%@", deviceUUID, lesson.lessonID];
    
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:relativeRequestPath
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                    {
                                        [formData appendPartWithFormData:[message dataUsingEncoding:NSUTF8StringEncoding] name:@"message"];
                                    }
                                    ];
    
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failure)
                                              failure(error);
                                          NSLog(@"Message failed:%@", [error localizedDescription]);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)deleteLesson:(Lesson *)lesson
           onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *relativeRequestPath = [NSString stringWithFormat:@"lessons/%@", lesson.lessonID];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:deviceUUID forKey:@"userCode"];
    [params setObject:lesson.lessonCode forKey:@"lessonCode"];
    [params setObject:@"delete" forKey:@"action"];
    
    self.hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    self.hud.delegate = self;
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Deleting from server";
    
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:relativeRequestPath parameters:params];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          [self hudHide];
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          if (failure)
                                              failure(error);
                                          NSLog(@"Delete failed:%@", [error localizedDescription]);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

// http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;
{
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    }
    
    // In the right or left cases, we need to switch scaledWidth and scaledHeight,
    // and also the thumbnail point
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, M_PI_2); // + 90 degrees
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        thumbnailPoint = CGPointMake(thumbnailPoint.y, thumbnailPoint.x);
        CGFloat oldScaledWidth = scaledWidth;
        scaledWidth = scaledHeight;
        scaledHeight = oldScaledWidth;
        
        CGContextRotateCTM (bitmap, -M_PI_2); // - 90 degrees
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, -M_PI); // - 180 degrees
    }
    
    CGContextDrawImage(bitmap, CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledWidth, scaledHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return newImage; 
}

- (void)syncCurrentUserProfileOnSuccess:(void (^)())success onFailure:(void (^)(NSError *))failure {
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@", deviceUUID];
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:relativeRequestPath
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
                                    {
                                        [formData appendPartWithFormData:[me.username dataUsingEncoding:NSUTF8StringEncoding]
                                                                    name:@"username"];
                                        if (me.learningLanguageTag)
                                            [formData appendPartWithFormData:[me.learningLanguageTag dataUsingEncoding:NSUTF8StringEncoding]
                                                                        name:@"learningLanguageTag"];
                                        if (me.nativeLanguageTag)
                                            [formData appendPartWithFormData:[me.nativeLanguageTag dataUsingEncoding:NSUTF8StringEncoding]
                                                                        name:@"nativeLanguageTag"];
                                        if (me.location)
                                            [formData appendPartWithFormData:[me.location dataUsingEncoding:NSUTF8StringEncoding]
                                                                        name:@"location"];
                                        if (me.photo) {
                                            UIImage *thumbnail = [NetworkManager imageWithImage:me.photo scaledToSizeWithSameAspectRatio:CGSizeMake(100, 100)];
                                            NSData *JPEGdata = UIImageJPEGRepresentation(thumbnail, 0.8);
                                            [formData appendPartWithFileData:JPEGdata
                                                                        name:@"photo"
                                                                    fileName:@"myPhoto.jpg"
                                                                    mimeType:@"image/jpg"];
                                        }
                                    }];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          NSString *username = [(NSDictionary *)JSON objectForKey:@"username"];
                                          if (![me.username isEqualToString:username]) {
                                              me.username = username;
                                              [me syncToDisk];
                                          }
                                          self.recommendedLessonsTmp = [(NSDictionary *)JSON objectForKey:@"recommendedLessons"];
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          NSLog(@"syncProfile failed:%@", [error localizedDescription]);
                                          if (failure)
                                              failure(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (NSArray *)recommendedLessons
{
    return _recommendedLessonsTmp;
}

- (void)markEventWithIDAsRead:(NSNumber *)eventID onSuccess:(void(^)())success onFailure:(void(^)(NSError *error))failure
{
    Profile *me = [Profile currentUserProfile];
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/%@/markEventAsRead", me.usercode];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:eventID forKey:@"id"];

    self.hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    self.hud.delegate = self;
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Marking as read";
    
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:relativeRequestPath parameters:params];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          [self hudHide];
                                          if (success)
                                              success();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          if (failure)
                                              failure(error);
                                          NSLog(@"Mark read failed:%@", [error localizedDescription]);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)lessonsWithSearch:(NSString *)searchString languageTag:(NSString *)tag return:(void(^)(NSArray *retLessons))returnBlock
{
    Profile *me = [Profile currentUserProfile];
    NSString *deviceUUID = me.usercode;
    
    // Transfer parameters
    NSString *relativeRequestPath = [NSString stringWithFormat:@"lessons/%@/?search=%@&userCode=%@", tag, searchString, deviceUUID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET"
                                                                 path:relativeRequestPath
                                                           parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          NSMutableArray *lessons = [NSMutableArray array];
                                          for (id item in (NSArray *)JSON) {
                                              NSData *data = [NSJSONSerialization dataWithJSONObject:item options:nil error:nil];
                                              [lessons addObject:[Lesson lessonWithJSON:data]];
                                          }
                                          returnBlock(lessons);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          [self hudFlashError:error];
                                          NSLog(@"Error searching lessons:%@", [error localizedDescription]);
                                      }];
    
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}


///////////////// GUI

- (void)hudHide
{
    [self.hud hide:YES afterDelay:0];
}

- (void)hudFlashError:(NSError *)error
{
    [self.hud hide:YES afterDelay:0];
    self.hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] keyWindow] animated:YES];
    self.hud.delegate = self;
    //hud.labelText = error.localizedDescription;
    //hud.labelText = @"Network connection failed";
    self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
    UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view.text = error.localizedDescription;
    view.font = self.hud.labelFont;
    view.textColor = [UIColor whiteColor];
    view.backgroundColor = [UIColor clearColor];
    [view sizeToFit];
    self.hud.customView = view;
    self.hud.mode = MBProgressHUDModeCustomView;
    [self.hud hide:YES afterDelay:1.5];
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

@end
