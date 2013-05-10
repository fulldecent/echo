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

#define kWordID @"wordID"
#define kWordCode @"wordCode"
#define kUserID @"userID"
#define kUserName @"userName"
#define kFiles @"files"
#define kCompleted @"completed"

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

+ (Lesson *)lessonWithJSON:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
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
    if ([packed objectForKey:kDetail])
        retval.detail = [packed objectForKey:kDetail];
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
    
    if (retval.detail) {
        for (id detail in retval.detail)
            if (![detail isKindOfClass:[NSString class]])
                return nil;
    }
    
    if ([retval.words isKindOfClass:[NSArray class]]) {
        for (id packedWord in [packed objectForKey:kWords]) {
            
            Word *newWord = [[Word alloc] init];
            newWord.wordID = [packedWord objectForKey:kWordID];
            if ([packedWord objectForKey:kWordCode])
                newWord.wordCode = [packedWord objectForKey:kWordCode];
            else
                newWord.wordCode = [NSString string];
            newWord.languageTag = [packedWord objectForKey:kLanguageTag];
            newWord.name = [packedWord objectForKey:kName];
            newWord.detail = [packedWord objectForKey:kDetail];
            if (newWord.detail) {
                for (id str in newWord.detail)
                    if (![str isKindOfClass:[NSString class]]) {
                        NSLog(@"Malformed word detail %@ with class %@", str, [str class]);
                        return nil;
                    }
            }
            
            newWord.userID = [packedWord objectForKey:kUserID];
            newWord.userName = [packedWord objectForKey:kUserName];
            newWord.completed = [packedWord objectForKey:kCompleted];
            
            NSMutableArray *newFiles = [[NSMutableArray alloc] init];
            for (id file in [packedWord objectForKey:kFiles]) {
                if ([file isKindOfClass:[NSString class]])
                    [newFiles addObject:file];
                else if ([file isKindOfClass:[NSNumber class]])
                    [newFiles addObject:[NSString stringWithFormat:@"%d", [(NSNumber *)file integerValue]]];
                else
                    NSLog(@"Malformed word file %@ with class %@", file, [file class]);                    
            }
            newWord.files = newFiles;
            
            [words addObject:newWord];
        }
    }
    retval.words = words;

    return retval;
}

-(NSData *)JSON 
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (self.lessonID)
        [dict setObject:self.lessonID forKey:kLessonID];
    if (self.lessonCode)
        [dict setObject:self.lessonCode forKey:kLessonCode];
    if (self.languageTag)
        [dict setObject:self.languageTag forKey:kLanguageTag];
    if (self.name)
        [dict setObject:self.name forKey:kName];
    if (self.detail)
        [dict setObject:self.detail forKey:kDetail];
    if (self.version)
        [dict setObject:self.version forKey:kVersion];
    if (self.serverVersion)
        [dict setObject:self.serverVersion forKey:kServerVersion];
    if (self.userID)
        [dict setObject:self.userID forKey:kUserID];
    if (self.userName)
        [dict setObject:self.userName forKey:kUserName];
    if (self.submittedLikeVote && [self.submittedLikeVote boolValue])
        [dict setObject:self.submittedLikeVote forKey:kSubmittedLikeVote];
    
    NSMutableArray *words = [[NSMutableArray alloc] init];
    for (Word *word in self.words) {
        NSMutableDictionary *wordDict = [[NSMutableDictionary alloc] init];
        if (word.wordID)
            [wordDict setObject:word.wordID forKey:kWordID];
        if (word.wordCode)
            [wordDict setObject:word.wordCode forKey:kWordCode];
        if (word.languageTag)
            [wordDict setObject:word.languageTag forKey:kLanguageTag];
        if (word.name)
            [wordDict setObject:word.name forKey:kName];
        if (word.detail)
            [wordDict setObject:word.detail forKey:kDetail];
        if (word.userName)
            [wordDict setObject:word.userName forKey:kUserName];
        if (word.userID)
            [wordDict setObject:word.userID forKey:kUserID];
        if (word.files)
            [wordDict setObject:word.files forKey:kFiles];
        if (word.completed)
            [wordDict setObject:word.completed forKey:kCompleted];
        [words addObject:wordDict];
    }
    
    [dict setObject:words forKey:kWords];

    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
}

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    if ([self.lessonCode length] > 0)
        return [documentsPath stringByAppendingPathComponent:self.lessonCode];
    else
        return [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [self.lessonID integerValue]]];
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
}

- (void)removeStaleFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    for (NSString *wordOnDisk in [fileManager contentsOfDirectoryAtPath:self.filePath error:nil]) {
        NSString *wordPath = [self.filePath stringByAppendingPathComponent:wordOnDisk];
        BOOL willKeepWord = NO;
        for (Word *word in self.words) {
            NSString *wordPath;
            if (word.wordCode) {
                if ([wordOnDisk isEqualToString:word.wordCode]) {
                    willKeepWord = YES;
                    wordPath = [self.filePath stringByAppendingPathComponent:word.wordCode];
                }
            } else {
                if ([wordOnDisk isEqualToString:[NSString stringWithFormat:@"%d", [word.wordID integerValue]]]) {
                    willKeepWord = YES;
                    wordPath = [self.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [word.wordID integerValue]]];
                }
            }
            if (willKeepWord) {
                for (NSString *fileOnDisk in [fileManager contentsOfDirectoryAtPath:wordPath error:nil]) {
                    NSString *filePath = [wordPath stringByAppendingPathComponent:fileOnDisk];
                    if (![word.files containsObject:fileOnDisk])
                    {
                        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
                            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
                        }
                    }
                }
                break;
            }
        }
        if (!willKeepWord) {
            if ([fileManager removeItemAtPath:wordPath error:&error] == NO) {
                NSLog(@"removeItemAtPath %@ error:%@", wordPath, error);
            }

        }
    }
}

- (NSArray *)listOfMissingFiles // return: [{"word":Word *,"fileID":NSNumber *},...]
{
    NSMutableArray *missingFiles = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (Word *word in self.words) {
        NSString *wordPath;
        if ([word.wordCode length])
            wordPath = [self.filePath stringByAppendingPathComponent:word.wordCode];
        else
            wordPath = [self.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [word.wordID integerValue]]];
        for (NSString *file in word.files) {
            NSString *filePath = [wordPath stringByAppendingPathComponent:file];
            if (![fileManager fileExistsAtPath:filePath]) {
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:word, @"word", file, @"fileID", nil];
                [missingFiles addObject:dict];
            }
        }
    }
    return missingFiles;
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

- (BOOL)isEditable
{
    return [self.lessonCode length] > 0;
}

- (BOOL)isShared
{
    return ([self.lessonID integerValue] > 0 && [self.lessonCode length] > 0) || [self.name isEqualToString:@"PRACTICE"];
}

- (NSNumber *)portionComplete
{
    int numerator = 0;
    for (Word *word in self.words)
        if (word.completed && word.completed.boolValue)
            numerator++;
    return [NSNumber numberWithFloat:(float)numerator/self.words.count];    
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NSLog(@"LESSON IS COPYING! %@", self);
    
    Lesson *copy = [[Lesson alloc] init];
    copy.languageTag = [self.languageTag copy];
    copy.name = [self.name copy];
    copy.detail = [[NSDictionary alloc] initWithDictionary:self.detail copyItems:YES];
    copy.version = [self.version copy];
    copy.serverVersion = [self.serverVersion copy];
    copy.words = [[NSArray alloc] initWithArray:self.words copyItems:YES];
    copy.userName = [self.userName copy];
    copy.lessonID = [self.lessonID copy];
    return copy;
}

#pragma NSObject

-(NSString *) description {
    return [NSString stringWithFormat:@"ID: %d; code: %@; name: %@", [self.lessonID integerValue], self.lessonCode, self.name];
}

@end
