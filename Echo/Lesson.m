//
//  Category.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Lesson.h"
#import "Word.h"
#import "Languages.h"
#import "Audio.h"
#import "Profile.h"

@interface Lesson() 
+ (NSString *)makeUUID;
@end

@implementation Lesson
@synthesize lessonID = _lessonID;
@synthesize lessonCode = _lessonCode;
@synthesize languageTag = _languageTag;
@synthesize name = _name;
@synthesize detail = _detail;
@synthesize version = _version;
@synthesize serverVersion = _serverVersion;
@synthesize words = _words;
@synthesize userID = _userID;
@synthesize userName = _userName;
@synthesize submittedLikeVote = _submittedLikeVote;

#define kLessonID @"lessonID"
#define kLessonCode @"lessonCode"
#define kLanguageTag @"languageTag"
#define kName @"name"
#define kDetail @"detail"
#define kVersion @"version"
#define kServerVersion @"serverVersion"
#define kUpdated @"updated"
#define kWords @"words"
#define kSubmittedLikeVote @"submittedLikeVote"
#define kLikes @"likes"
#define kFlags @"flags"
#define kTranslations @"translations"

#define kWordID @"wordID"
#define kWordCode @"wordCode"
#define kUserID @"userID"
#define kUserName @"userName"
#define kFiles @"files"
#define kCompleted @"completed"

#define kFileID @"fileID"
#define kFileCode @"fileCode"

+ (NSString *)makeUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

- (NSString *)lessonCode
{
    if (!_lessonCode)
        _lessonCode = [Lesson makeUUID];
    return _lessonCode;
}

- (NSArray *)words
{
    if (!_words)
        _words = [NSArray array];
    return _words;
}

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    if (self.lessonID.intValue)
        return [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [self.lessonID integerValue]]];
    else
        return [documentsPath stringByAppendingPathComponent:self.lessonCode];
}

- (void)setToLesson:(Lesson *)lesson
{
    if (lesson.lessonID)
        self.lessonID = lesson.lessonID;
    if (lesson.lessonCode)
        self.lessonCode = lesson.lessonCode;
    /* else
        retval.lessonCode = [NSString string]; */
    if (lesson.languageTag)
        self.languageTag = lesson.languageTag;
    if (lesson.name)
        self.name = lesson.name;
    if (lesson.detail)
        self.detail = lesson.detail;
    if (lesson.version)
        self.version = lesson.version;
    if (lesson.serverVersion)
        self.serverVersion = lesson.serverVersion;
    if (lesson.userID)
        self.userID = lesson.userID;
    if (lesson.userName)
        self.userName = lesson.userName;
    if (lesson.submittedLikeVote && [lesson.submittedLikeVote boolValue])
        self.submittedLikeVote = lesson.submittedLikeVote;
    if (lesson.words)
        self.words = lesson.words;
    for (Word *word in lesson.words) {
        word.lesson = self;
    }
    if (lesson.translations)
        self.translations = lesson.translations;
}

- (void)removeStaleFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    for (NSString *wordOnDisk in [fileManager contentsOfDirectoryAtPath:self.filePath error:nil]) {
        NSString *wordPath = [self.filePath stringByAppendingPathComponent:wordOnDisk];
        BOOL willKeepWord = NO;
        for (Word *word in self.words) {
            if ([word.filePath isEqualToString:wordPath]) {
                willKeepWord = YES;
                break;
            }
            if (willKeepWord) {
                for (NSString *fileOnDisk in [fileManager contentsOfDirectoryAtPath:wordPath error:nil]) {
                    NSString *filePath = [wordPath stringByAppendingPathComponent:fileOnDisk];
                    BOOL willKeepFile = NO;
                    for (Audio *audio in word.files) {
                        if ([audio.filePath isEqualToString:filePath]) {
                            willKeepFile = YES;
                            break;
                        }
                    }
                    if (!willKeepFile) {
                        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
                            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
                        }
                    }
                }
            }
        }
        if (!willKeepWord) {
            if ([fileManager removeItemAtPath:wordPath error:&error] == NO) {
                NSLog(@"removeItemAtPath %@ error:%@", wordPath, error);
            }
        }
    }
}

- (NSArray *)listOfMissingFiles // return: [{"word":Word *,"audio":Audio *},...]
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    for (Word *word in self.words) {
        NSArray *wordMissingFiles = [word listOfMissingFiles];
        for (Audio *file in wordMissingFiles) {
            NSMutableDictionary *entry = [[NSMutableDictionary alloc] init];
            [entry setObject:file forKey:@"audio"];
            [entry setObject:word forKey:@"word"];
            [retval addObject:entry];
        }
    }
    return retval;
}

- (BOOL)isOlderThanServer
{
    return [self.version integerValue] < [self.serverVersion integerValue];
}

- (BOOL)isNewerThanServer
{
    return [self.version integerValue] > [self.serverVersion integerValue] || [self.serverVersion integerValue] == 0;
}

- (BOOL)isUsable
{
    return [self.lessonCode length] > 0 || [self.version integerValue] > 0;
}

- (BOOL)isByCurrentUser
{
    Profile *me = [Profile currentUserProfile];
    return me.userID && [self.userID isEqualToNumber:me.userID];
}

- (BOOL)isShared
{
    return [self.lessonID integerValue] || [self.version integerValue];
}

- (NSNumber *)portionComplete
{
    int numerator = 0;
    for (Word *word in self.words)
        if (word.completed && word.completed.boolValue)
            numerator++;
    return [NSNumber numberWithFloat:(float)numerator/self.words.count];    
}

- (Word *)wordWithCode:(NSString *)wordCode
{
    for (Word *word in self.words)
        if ([word.wordCode isEqualToString:wordCode])
            return word;
    return nil;
}

- (Word *)wordWithCode:(NSString *)wordCode translatedTo:(NSString *)langTag
{
    Lesson *translation = [self.translations objectForKey:langTag];
    return [translation wordWithCode:wordCode];    
}

#pragma NSObject

-(NSString *) description {
    return [NSString stringWithFormat:@"ID: %d; code: %@; name: %@", [self.lessonID integerValue], self.lessonCode, self.name];
}

+ (Lesson *)lessonWithDictionary:(NSDictionary *)packed
{
    Lesson *retval = [[Lesson alloc] init];
    if ([packed objectForKey:kLessonID])
        retval.lessonID = [packed objectForKey:kLessonID];
    if ([packed objectForKey:kLessonCode])
        retval.lessonCode = [packed objectForKey:kLessonCode];
    else
        retval.lessonCode = [NSString string];
    if ([packed objectForKey:kLanguageTag])
        retval.languageTag = [packed objectForKey:kLanguageTag];
    if ([packed objectForKey:kName])
        retval.name = [packed objectForKey:kName];
    if ([packed objectForKey:kDetail]) {
        // Backwards compatibility from version <= 1.0.9
        if ([[packed objectForKey:kDetail] isKindOfClass:[NSDictionary class]]) {
            if ([(NSDictionary *)[packed objectForKey:kDetail] objectForKey:retval.languageTag])
                retval.detail = [(NSDictionary *)[packed objectForKey:kDetail] objectForKey:retval.languageTag];
        } else
            retval.detail = [packed objectForKey:kDetail];
    }
    if ([packed objectForKey:kVersion])
        retval.version = [packed objectForKey:kVersion];
    if ([packed objectForKey:kServerVersion])
        retval.serverVersion = [packed objectForKey:kServerVersion];
    if ([packed objectForKey:kUpdated])
        retval.serverVersion = [packed objectForKey:kUpdated];
    if ([packed objectForKey:kUserID])
        retval.userID = [packed objectForKey:kUserID];
    if ([packed objectForKey:kUserName])
        retval.userName = [packed objectForKey:kUserName];
    if ([packed objectForKey:kSubmittedLikeVote])
        retval.submittedLikeVote = [packed objectForKey:kSubmittedLikeVote];
    if ([packed objectForKey:kLikes])
        retval.numLikes = [packed objectForKey:kLikes];
    if ([packed objectForKey:kFlags])
        retval.numFlags = [packed objectForKey:kFlags];
    NSMutableArray *words = [[NSMutableArray alloc] init];
    if ([[packed objectForKey:kWords] isKindOfClass:[NSArray class]]) {
        for (NSDictionary *packedWord in [packed objectForKey:kWords]) {
            Word *newWord = [Word wordWithDictionary:packedWord];
            newWord.lesson = retval;
            [words addObject:newWord];
        }
    }
    retval.words = words;
    NSMutableDictionary *translatedLessons = [[NSMutableDictionary alloc] init];
    if ([[packed objectForKey:kTranslations] isKindOfClass:[NSDictionary class]]) {
        for (NSString *langTag in [packed objectForKey:kTranslations]) {
            NSDictionary *packedTranslation = [[packed objectForKey:kTranslations] objectForKey:langTag];
            Lesson *newTranslation = [Lesson lessonWithDictionary:packedTranslation];
            [translatedLessons setObject:newTranslation forKey:langTag];
        }
    }
    retval.translations = translatedLessons;
    return retval;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    if (self.lessonID)
        [retval setObject:self.lessonID forKey:kLessonID];
    if (self.lessonCode)
        [retval setObject:self.lessonCode forKey:kLessonCode];
    if (self.languageTag)
        [retval setObject:self.languageTag forKey:kLanguageTag];
    if (self.name)
        [retval setObject:self.name forKey:kName];
    if (self.detail)
        [retval setObject:self.detail forKey:kDetail];
    if (self.version)
        [retval setObject:self.version forKey:kVersion];
    if (self.serverVersion)
        [retval setObject:self.serverVersion forKey:kServerVersion];
    if (self.userID)
        [retval setObject:self.userID forKey:kUserID];
    if (self.userName)
        [retval setObject:self.userName forKey:kUserName];
    if (self.submittedLikeVote && [self.submittedLikeVote boolValue])
        [retval setObject:self.submittedLikeVote forKey:kSubmittedLikeVote];
    NSMutableArray *packedWords = [[NSMutableArray alloc] init];
    for (Word *word in self.words) {
        NSDictionary *packedWord = [word toDictionary];
        [packedWords addObject:packedWord];
    }
    [retval setObject:packedWords forKey:kWords];
    if (self.translations.count) {
        NSMutableDictionary *packedTranslations = [[NSMutableDictionary alloc] init];
        for (NSString *langTag in self.translations) {
            Lesson *translation = [self.translations objectForKey:langTag];
            NSDictionary *packedTranslation = [translation toDictionary];
            [packedTranslations setObject:packedTranslation forKey:langTag];
        }
        [retval setObject:packedTranslations forKey:kTranslations];
    }
    return retval;
}

+ (Lesson *)lessonWithJSON:(NSData *)data
{
    NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [Lesson lessonWithDictionary:packed];
}

- (NSData *)JSON
{
    return [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:nil];
}


@end
