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
#import "Audio.h"
#import "NSData+Base64.h" // from some submodule

#define SERVER_ECHO_API_URL @"http://learnwithecho.com/api/2.0/"

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

- (AFHTTPClient *)HTTPclient
{
    if (!_HTTPclient) {
        Profile *me = [Profile currentUserProfile];
        _HTTPclient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:SERVER_ECHO_API_URL]];
        _HTTPclient.parameterEncoding = AFJSONParameterEncoding;
        // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        //[_HTTPclient setDefaultHeader:@"Accept" value:@"application/json"];
        [_HTTPclient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [_HTTPclient setAuthorizationHeaderWithUsername:@"xx" password:me.usercode];
    }
    return _HTTPclient;
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
 //      PUT     users/me/likesLessons/175
 //      DELETE  users/me/likesLessons/175
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

- (void)getAudioWithID:(NSNumber *)audioID
          withProgress:(void(^)(NSData *audio, NSNumber *progress))progressBlock
             onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"audio/%@.caf", audioID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET" path:relativePath parameters:nil];
    AFHTTPRequestOperation *HTTPop = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [HTTPop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (progressBlock)
             progressBlock((NSData *)responseObject, [NSNumber numberWithInt:1]);
     }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (failureBlock)
             failureBlock(error);
     }];
    [HTTPop setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead)
     {
         if (totalBytesExpectedToRead > 0 && totalBytesRead < totalBytesExpectedToRead) {
             if (progressBlock)
                 progressBlock(nil, [NSNumber numberWithFloat:totalBytesRead / totalBytesExpectedToRead]);
         }
     }];
    [self.HTTPclient enqueueHTTPRequestOperation:HTTPop];
}

- (void)deleteLessonWithID:(NSNumber *)lessonID
                 onSuccess:(void(^)())successBlock
                 onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"lessons/%d", lessonID.intValue];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"DELETE" path:relativePath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)getLessonWithID:(NSNumber *)lessonID asPreviewOnly:(BOOL)preview
              onSuccess:(void(^)(Lesson *lesson))successBlock
              onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath;
    if (preview)
        relativePath = [NSString stringWithFormat:@"lessons/%@.json?preview=yes", lessonID];
    else
        relativePath = [NSString stringWithFormat:@"lessons/%@.json", lessonID];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET" path:relativePath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          NSData *data = [NSJSONSerialization dataWithJSONObject:JSON options:nil error:nil];
                                          Lesson *lesson = [Lesson lessonWithJSON:data];
                                          if (successBlock)
                                              successBlock(lesson);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)searchLessonsWithLangTag:(NSString *)langTag andSearhText:(NSString *)searchText
                       onSuccess:(void(^)(NSArray *lessonPreviews))successBlock
                       onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativeRequestPath = [NSString stringWithFormat:@"lessons/%@/?search=%@", langTag, searchText];
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
                                          if (successBlock)
                                              successBlock(lessons);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)postLesson:(Lesson *)lesson
         onSuccess:(void(^)(NSNumber *newLessonID, NSNumber *newServerVersion, NSArray *neededWordAndFileCodes))successBlock
         onFailure:(void(^)(NSError *error))failureBlock
{
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:@"lessons/" parameters:nil];
    request.HTTPBody = [lesson JSON];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock([JSON objectForKey:@"lessonID"],
                                                           [JSON objectForKey:@"updated"],
                                                           [JSON objectForKey:@"neededFiles"]); 
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)putTranslation:(Lesson *)translation asLangTag:(NSString *)langTag versionOfLessonWithID:(NSNumber *)lessonID
             onSuccess:(void(^)(NSNumber *translationLessonID, NSNumber *translationVersion))successBlock
             onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"lessons/%d/translations/%@",
                              lessonID.intValue,
                              langTag];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"PUT" path:relativePath parameters:nil];
    request.HTTPBody = [translation JSON];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock([JSON objectForKey:@"lessonID"],
                                                           [JSON objectForKey:@"updated"]);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)putAudioFileAtPath:(NSString *)filePath forLesson:(Lesson *)lesson withWord:(Word *)word usingCode:(NSString *)code
              withProgress:(void(^)(NSNumber *progress))progressBlock
                 onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativePath =[NSString stringWithFormat:@"lessons/%@/words/%@/files/%@.caf", lesson.lessonCode, word.wordCode, code];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"PUT" path:relativePath parameters:nil];
    request.HTTPBody = [NSData dataWithContentsOfFile:filePath];
    AFHTTPRequestOperation *HTTPop = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [HTTPop setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (progressBlock)
             progressBlock([NSNumber numberWithInt:1]);
     }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (failureBlock)
             failureBlock(error);
     }];
    [HTTPop setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead)
     {
         if (totalBytesExpectedToRead > 0 && totalBytesRead < totalBytesExpectedToRead) {
             if (progressBlock)
                 progressBlock([NSNumber numberWithFloat:totalBytesRead / totalBytesExpectedToRead]);
         }
     }];
    [self.HTTPclient enqueueHTTPRequestOperation:HTTPop];
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
    Profile *me = [Profile currentUserProfile];
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] init];
    [requestData setObject:me.username forKey:@"username"];
    [requestData setObject:me.usercode forKey:@"userCode"];
    if (me.learningLanguageTag)
        [requestData setObject:me.learningLanguageTag forKey:@"learningLanguageTag"];
    if (me.nativeLanguageTag)
        [requestData setObject:me.nativeLanguageTag forKey:@"nativeLanguageTag"];
    if (me.location)
        [requestData setObject:me.location forKey:@"location"];
    if (me.deviceToken)
        [requestData setObject:me.deviceToken forKey:@"deviceToken"];
    if (me.photo) {
        UIImage *thumbnail = [NetworkManager imageWithImage:me.photo scaledToSizeWithSameAspectRatio:CGSizeMake(100, 100)];
        NSData *JPEGdata = UIImageJPEGRepresentation(thumbnail, 0.8);
        [requestData setObject:[JPEGdata base64EncodedString] forKey:@"photo"];
    }
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:@"users/" parameters:nil];
    NSData *requestDataJSON = [NSJSONSerialization dataWithJSONObject:requestData options:0 error:nil];
    request.HTTPBody = requestDataJSON;
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
     {
         NSString *username = [(NSDictionary *)JSON objectForKey:@"username"];
         NSNumber *userID = [(NSDictionary *)JSON objectForKey:@"userID"];
         NSMutableArray *recommendedLessons = [[NSMutableArray alloc] init];
         for (id lessonJSONDecoded in [(NSDictionary *)JSON objectForKey:@"recommendedLessons"]) {
             NSData *lessonJSON = [NSJSONSerialization dataWithJSONObject:lessonJSONDecoded options:0 error:nil];
             [recommendedLessons addObject:[Lesson lessonWithJSON:lessonJSON]];
         }
         if (successBlock)
             successBlock(username, userID, recommendedLessons);
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         if (failureBlock)
             failureBlock(error);
     }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
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
        [lessonTimestampsToCheck addObject:lesson.serverVersion];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    [requestParams setObject:lessonIDsToCheck forKey:@"lessonIDs"];
    [requestParams setObject:lessonTimestampsToCheck forKey:@"lessonTimestamps"];
    if ([defaults objectForKey:@"lastLessonSeen"])
        [requestParams setObject:[defaults objectForKey:@"lastLessonSeen"] forKey:@"lastLessonSeen"];
    if ([defaults objectForKey:@"lastMessageSeen"])
        [requestParams setObject:[defaults objectForKey:@"lastMessageSeen"] forKey:@"lastMessageSeen"];
    NSString *relativeRequestPath = @"users/me/updates";
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"GET" path:relativeRequestPath parameters:requestParams];
    
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock([JSON objectForKey:@"updatedLessons"],
                                                           [JSON objectForKey:@"newLessons"],
                                                           [JSON objectForKey:@"unreadMessages"]);
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)doLikeLesson:(Lesson *)lesson
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/me/likesLessons/%d", lesson.lessonID.intValue];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"PUT" path:relativeRequestPath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)doUnlikeLesson:(Lesson *)lesson
             onSuccess:(void(^)())successBlock
             onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/me/likesLessons/%d", lesson.lessonID.intValue];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"DELETE" path:relativeRequestPath parameters:nil];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)doFlagLesson:(Lesson *)lesson withReason:(enum NetworkManagerFlagReason)flagReason
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativeRequestPath = [NSString stringWithFormat:@"users/me/flagsLessons/%d", lesson.lessonID.intValue];
    NSString *flagString = [NSString stringWithFormat:@"%d", flagReason];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"PUT" path:relativeRequestPath parameters:nil];
    request.HTTPBody = [flagString dataUsingEncoding:NSUTF8StringEncoding];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)getWordWithID:(NSNumber *)wordID
            onSuccess:(void(^)(Word *word))successBlock
            onFailure:(void(^)(NSError *error))failureBlock
{
    //TODO: do this
}

- (void)deleteWordWithID:(NSNumber *)wordID
               onSuccess:(void(^)())successBlock
               onFailure:(void(^)(NSError *error))failureBlock
{
    //TODO: do this
}

- (void)postWord:(Word *)word AsPracticeWithFilesInPath:(NSString *)filePath
    withProgress:(void(^)(NSNumber *progress))progressBlock
       onFailure:(void(^)(NSError *error))failureBlock
{
    NSMutableURLRequest *request = [self.HTTPclient multipartFormRequestWithMethod:@"POST"
                                                                              path:@"words/practice/"
                                                                        parameters:nil
                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
    {
        [formData appendPartWithFormData:[word JSON] name:@"word"];
        int fileNum = 0;
        for (Audio *file in word.files) {
            fileNum++;
            NSString *fileName = [NSString stringWithFormat:@"file%d", fileNum];
            NSData *fileData = [NSData dataWithContentsOfFile:[file filePath]];
            [formData appendPartWithFileData:fileData name:fileName fileName:fileName mimeType:@"audio/mp4a-latm"];
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
            failureBlock(error);
    }];
    [JSONop setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead)
     {
         if (totalBytesExpectedToRead > 0 && totalBytesRead < totalBytesExpectedToRead) {
             if (progressBlock)
                 progressBlock([NSNumber numberWithFloat:totalBytesRead / totalBytesExpectedToRead]);
         }
     }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

- (void)postWord:(Word *)word withFilesInPath:(NSString *)filePath asReplyToWordWithID:(NSNumber *)wordID
    withProgress:(void(^)(NSNumber *progress))progressBlock
       onFailure:(void(^)(NSError *error))failureBlock
{
    //TODO: do this
}

- (void)deleteEventWithID:(NSNumber *)eventID
                onSuccess:(void(^)())successBlock
                onFailure:(void(^)(NSError *error))failureBlock
{
    //TODO: do this
}

- (void)postFeedback:(NSString *)feedback toAuthorOfLessonWithID:(NSNumber *)lessonID
           onSuccess:(void(^)())successBlock
           onFailure:(void(^)(NSError *error))failureBlock
{
    NSString *relativeRequestPath = [NSString stringWithFormat:@"events/feedbackLesson/%d/", lessonID.intValue];
    NSMutableURLRequest *request = [self.HTTPclient requestWithMethod:@"POST" path:relativeRequestPath parameters:nil];
    request.HTTPBody = [feedback dataUsingEncoding:NSUTF8StringEncoding];
    AFJSONRequestOperation *JSONop = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                      {
                                          if (successBlock)
                                              successBlock();
                                      }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                      {
                                          if (failureBlock)
                                              failureBlock(error);
                                      }];
    [self.HTTPclient enqueueHTTPRequestOperation:JSONop];
}

#pragma mark - Helper functions /////////////////////////////////////////////////

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
{
    for (Lesson *lessonToSync in lessons) {
        // Which direction is this motherfucter syncing?
        if (lessonToSync.isNewerThanServer)
            [self pushLessonWithFiles:lessonToSync withProgress:progressBlock onFailure:nil];
        else if (lessonToSync.isOlderThanServer || [[lessonToSync listOfMissingFiles] count])
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
    [self getLessonWithID:lessonToSync.lessonID asPreviewOnly:NO onSuccess:^(Lesson *retreivedLesson)
     {
         [lessonToSync setToLesson:retreivedLesson];
         NSMutableArray *neededAudios = [[NSMutableArray alloc] init];
         for (NSDictionary *audioAndWord in [lessonToSync listOfMissingFiles])
             [neededAudios addObject:[audioAndWord objectForKey:@"audio"]];         
         __block NSNumber *lessonProgress = [NSNumber numberWithInt:1];
         __block NSNumber *totalLessonProgress = [NSNumber numberWithInt:[neededAudios count]+1];
         
         if ([neededAudios count] == 0)
             lessonToSync.version = retreivedLesson.serverVersion;
         if (progressBlock)
             progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);
         
         for (Audio *file in neededAudios) {
             [self getAudioWithID:[file fileID] withProgress:^(NSData *audio, NSNumber *fileProgress)
              {
                  if ([fileProgress isEqualToNumber:[NSNumber numberWithInt:1]]) {
                      NSFileManager *fileManager = [NSFileManager defaultManager];
                      NSString *dirname = [file.filePath stringByDeletingLastPathComponent];
                      [fileManager createDirectoryAtPath:dirname withIntermediateDirectories:YES attributes:nil error:nil];
                      [audio writeToFile:file.filePath atomically:YES];                      
                      lessonProgress = [NSNumber numberWithInt:[lessonProgress integerValue]+1];
                      if ([lessonProgress isEqualToNumber:totalLessonProgress])
                          lessonToSync.version = retreivedLesson.serverVersion;
                      if (progressBlock)
                          progressBlock(lessonToSync, [NSNumber numberWithFloat:[lessonProgress floatValue]/[totalLessonProgress floatValue]]);
                      //TODO: Could do even more accurate progress reporting if we wanted
                  }
              } onFailure:^(NSError *error) {
              }];
         }
     } onFailure:^(NSError *error) {
         if (failureBlock) failureBlock(error);
     }];
}

// Side effect: will set the lesson ID if it is null and will update serverversion
- (void)pushLessonWithFiles:(Lesson *)lessonToSync
         withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
            onFailure:(void(^)(NSError *error))failureBlock
{
    [self postLesson:lessonToSync onSuccess:^(NSNumber *newLessonID, NSNumber *newServerVersion, NSArray *neededWordAndFileCodes)
     {
         __block NSNumber *lessonProgress = [NSNumber numberWithInt:1];
         __block NSNumber *totalLessonProgress = [NSNumber numberWithInt:[neededWordAndFileCodes count]+1];
         lessonToSync.lessonID = newLessonID;
         if ([neededWordAndFileCodes count] == 0)
             lessonToSync.version = lessonToSync.serverVersion = newServerVersion;
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
                      lessonProgress = [NSNumber numberWithInt:[lessonProgress integerValue]+1];
                      if ([lessonProgress isEqualToNumber:totalLessonProgress])
                          lessonToSync.version = lessonToSync.serverVersion = newServerVersion;
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

- (NSArray *)recommendedLessons
{
    return _recommendedLessonsTmp;
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
