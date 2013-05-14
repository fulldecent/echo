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
         NSNumber *ratio;
         if (totalBytesExpectedToRead == 0) ratio = [NSNumber numberWithInt:1];
         else ratio = [NSNumber numberWithInt:totalBytesRead / totalBytesExpectedToRead];
         if (progressBlock)
             progressBlock(nil, ratio);
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
    //TODO: do this
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
        if (!lesson.isShared)
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
    //TODO: do this
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

////////////////////////////////////////////////

- (void)syncLessons:(NSArray *)lessons
       withProgress:(void(^)(Lesson *lesson, NSNumber *progress))progressBlock
{
    for (Lesson *lessonToSync in lessons) {
        // Which direction is this motherfucter syncing?
        if ([[lessonToSync listOfMissingFiles] count] || lessonToSync.isOlderThanServer)
            [self pullLessonWithFiles:lessonToSync withProgress:progressBlock onFailure:nil];
        else if (lessonToSync.isEditable && lessonToSync.isNewerThanServer)
            [self pushLessonWithFiles:lessonToSync withProgress:progressBlock onFailure:nil];
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

///////OLD STUFF////////////////////////////////////////////////////////////
////////////////////////////////////////


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
                                        if (me.deviceToken)
                                            [formData appendPartWithFormData:[me.deviceToken dataUsingEncoding:NSUTF8StringEncoding]
                                                                        name:@"deviceToken"];
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
    [sharedHUD hide:YES afterDelay:1.5];
}


@end
