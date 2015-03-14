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

@implementation Lesson

#define kLessonID @"lessonID"
#define kLessonCode @"lessonCode"
#define kLanguageTag @"languageTag"
#define kName @"name"
#define kDetail @"detail"
#define kServerTimeOfLastCompletedSync @"updated"
#define kLocalChangesSinceLastSync @"localChangesSinceLastSync"
#define kRemoteChangesSinceLastSync @"remoteChangesSinceLastSync"
#define kWords @"words"
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

- (NSString *)lessonCode
{
    if (!_lessonCode)
        _lessonCode = [[NSUUID UUID] UUIDString];
    return _lessonCode;
}

- (NSArray *)words
{
    if (!_words)
        _words = @[];
    return _words;
}

- (NSURL *)fileURL
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                         inDomains:NSUserDomainMask] lastObject];
    if (self.lessonID.intValue)
        return [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)[self.lessonID integerValue]]];
    else
        return [url URLByAppendingPathComponent:self.lessonCode];
}

- (void)setToLesson:(Lesson *)lesson
{
    if (lesson.lessonID)
        self.lessonID = lesson.lessonID;
    if (lesson.lessonCode)
        self.lessonCode = lesson.lessonCode;
    if (lesson.languageTag)
        self.languageTag = lesson.languageTag;
    if (lesson.name)
        self.name = lesson.name;
    if (lesson.detail)
        self.detail = lesson.detail;
    if (lesson.userID)
        self.userID = lesson.userID;
    if (lesson.userName)
        self.userName = lesson.userName;
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
    for (NSURL *wordOnDiskURL in [fileManager contentsOfDirectoryAtURL:self.fileURL includingPropertiesForKeys:nil options:nil error:nil]) {
        BOOL willKeepWord = NO;
        for (Word *word in self.words) {
            if ([word.fileURL isEqual:wordOnDiskURL]) {
                willKeepWord = YES;
                break;
            }
            if (willKeepWord) {
                for (NSURL *fileOnDiskURL in [fileManager contentsOfDirectoryAtURL:wordOnDiskURL includingPropertiesForKeys:nil options:nil error:nil]) {
                    BOOL willKeepFile = NO;
                    for (Audio *audio in word.files) {
                        if ([audio.fileURL isEqual:fileOnDiskURL]) {
                            willKeepFile = YES;
                            break;
                        }
                    }
                    if (!willKeepFile) {
                        if ([fileManager removeItemAtURL:fileOnDiskURL error:&error] == NO) {
                            NSLog(@"removeItemAtPath %@ error:%@", fileOnDiskURL, error);
                        }
                    }
                }
            }
        }
        if (!willKeepWord) {
            if ([fileManager removeItemAtURL:wordOnDiskURL error:&error] == NO) {
                NSLog(@"removeItemAtPath %@ error:%@", wordOnDiskURL, error);
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
            entry[@"audio"] = file;
            entry[@"word"] = word;
            [retval addObject:entry];
        }
    }
    return retval;
}

- (BOOL)isByCurrentUser
{
    Profile *me = [Profile currentUserProfile];
    return me.userID && [self.userID isEqualToNumber:me.userID];
}

- (BOOL)isShared
{
    return self.serverTimeOfLastCompletedSync.integerValue;
}

- (NSNumber *)portionComplete
{
    int numerator = 0;
    for (Word *word in self.words)
        if (word.completed && word.completed.boolValue)
            numerator++;
    return @((float)numerator/self.words.count);    
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
    Lesson *translation = (self.translations)[langTag];
    return [translation wordWithCode:wordCode];    
}

#pragma NSObject

- (NSString *) description {
    return [NSString stringWithFormat:@"ID: %ld; code: %@; name: %@", (long)[self.lessonID integerValue], self.lessonCode, self.name];
}

+ (Lesson *)lessonWithDictionary:(NSDictionary *)packed
{
    Lesson *retval = [[Lesson alloc] init];
    if (packed[kLessonID])
        retval.lessonID = packed[kLessonID];
    if (packed[kLessonCode])
        retval.lessonCode = packed[kLessonCode];
    else
        retval.lessonCode = [NSString string];
    if (packed[kLanguageTag])
        retval.languageTag = packed[kLanguageTag];
    if (packed[kName])
        retval.name = packed[kName];
    if (packed[kDetail]) {
        // Backwards compatibility from version <= 1.0.9
        if ([packed[kDetail] isKindOfClass:[NSDictionary class]]) {
            if (((NSDictionary *)packed[kDetail])[retval.languageTag])
                retval.detail = ((NSDictionary *)packed[kDetail])[retval.languageTag];
        } else
            retval.detail = packed[kDetail];
    }
    if (packed[kServerTimeOfLastCompletedSync])
        retval.serverTimeOfLastCompletedSync = packed[kServerTimeOfLastCompletedSync];
    if (packed[kLocalChangesSinceLastSync])
        retval.localChangesSinceLastSync = [(NSNumber *)packed[kLocalChangesSinceLastSync] boolValue];
    if (packed[kRemoteChangesSinceLastSync])
        retval.remoteChangesSinceLastSync = [(NSNumber *)packed[kRemoteChangesSinceLastSync] boolValue];
    if (packed[kUserID])
        retval.userID = packed[kUserID];
    if (packed[kUserName])
        retval.userName = packed[kUserName];
    if (packed[kLikes])
        retval.numLikes = packed[kLikes];
    if (packed[kFlags])
        retval.numFlags = packed[kFlags];
    NSMutableArray *words = [[NSMutableArray alloc] init];
    if ([packed[kWords] isKindOfClass:[NSArray class]]) {
        for (NSDictionary *packedWord in packed[kWords]) {
            Word *newWord = [Word wordWithDictionary:packedWord];
            newWord.lesson = retval;
            [words addObject:newWord];
        }
    }
    retval.words = words;
    NSMutableDictionary *translatedLessons = [[NSMutableDictionary alloc] init];
    if ([packed[kTranslations] isKindOfClass:[NSDictionary class]]) {
        for (NSString *langTag in packed[kTranslations]) {
            NSDictionary *packedTranslation = packed[kTranslations][langTag];
            Lesson *newTranslation = [Lesson lessonWithDictionary:packedTranslation];
            translatedLessons[langTag] = newTranslation;
        }
    }
    retval.translations = translatedLessons;
    return retval;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    if (self.lessonID)
        retval[kLessonID] = self.lessonID;
    if (self.lessonCode)
        retval[kLessonCode] = self.lessonCode;
    if (self.languageTag)
        retval[kLanguageTag] = self.languageTag;
    if (self.name)
        retval[kName] = self.name;
    if (self.detail)
        retval[kDetail] = self.detail;
    if (self.serverTimeOfLastCompletedSync)
        retval[kServerTimeOfLastCompletedSync] = self.serverTimeOfLastCompletedSync;
    retval[kLocalChangesSinceLastSync] = @(self.localChangesSinceLastSync);
    retval[kRemoteChangesSinceLastSync] = @(self.remoteChangesSinceLastSync);
    if (self.userID)
        retval[kUserID] = self.userID;
    if (self.userName)
        retval[kUserName] = self.userName;
    NSMutableArray *packedWords = [[NSMutableArray alloc] init];
    for (Word *word in self.words) {
        NSDictionary *packedWord = [word toDictionary];
        [packedWords addObject:packedWord];
    }
    retval[kWords] = packedWords;
    if (self.translations.count) {
        NSMutableDictionary *packedTranslations = [[NSMutableDictionary alloc] init];
        for (NSString *langTag in self.translations) {
            Lesson *translation = (self.translations)[langTag];
            NSDictionary *packedTranslation = [translation toDictionary];
            packedTranslations[langTag] = packedTranslation;
        }
        retval[kTranslations] = packedTranslations;
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
