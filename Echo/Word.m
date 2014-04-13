//
//  Word.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Word.h"
#import "Audio.h"
#import "Lesson.h"

@implementation Word
@synthesize wordID = _wordID;
@synthesize wordCode = _wordCode;
@synthesize languageTag = _languageTag;
@synthesize name = _name;
@synthesize detail = _detail;
@synthesize userID = _userID;
@synthesize userName = _userName;
@synthesize files = _files;
@synthesize completed = _completed;

#define kLanguageTag @"languageTag"
#define kName @"name"
#define kDetail @"detail"
#define kWordID @"wordID"
#define kWordCode @"wordCode"
#define kUserID @"userID"
#define kUserName @"userName"
#define kFiles @"files"
#define kCompleted @"completed"

#define kFileID @"fileID"
#define kFileCode @"fileCode"

- (NSArray *)listOfMissingFiles
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    for (Audio *file in self.files)
        if (!file.fileExistsOnDisk)
            [retval addObject:file];
    return retval;
}

- (NSString *)wordCode
{
    if (!_wordCode)
        _wordCode = [[NSUUID UUID] UUIDString];
    return _wordCode;
}

- (NSArray *)files
{
    if (!_files)
        _files = [NSArray array];
    return _files;
}

- (Audio *)fileWithCode:(NSString *)fileCode
{
    for (Audio *file in self.files)
        if ([file.fileCode isEqualToString:fileCode])
            return file;
    return nil;
}

- (NSString *)filePath
{
    if (!self.lesson.filePath)
        return NSTemporaryDirectory(); // a practice word
    if (self.wordID)
        return [self.lesson.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)[self.wordID integerValue]]];
    else
        return [self.lesson.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.wordCode]];
}

+ (Word *)wordWithDictionary:(NSDictionary *)packed
{
    Word *retval = [[Word alloc] init];
    NSAssert([packed isKindOfClass:[NSDictionary class]], @"trying to deserialize Word from something other than a dictionary");
    retval.wordID = [packed objectForKey:kWordID];
    if ([packed objectForKey:kWordCode])
        retval.wordCode = [packed objectForKey:kWordCode];
    else
        retval.wordCode = [NSString string];
    retval.languageTag = [packed objectForKey:kLanguageTag];
    retval.name = [packed objectForKey:kName];
    if ([[packed objectForKey:kDetail] isKindOfClass:[NSString class]])
        retval.detail = [packed objectForKey:kDetail];
    else if ([[packed objectForKey:kDetail] isKindOfClass:[NSDictionary class]]) // Backwards compatibility <= 1.0.9
        retval.detail = [(NSDictionary *)[packed objectForKey:kDetail] objectForKey:retval.languageTag];
    retval.userID = [packed objectForKey:kUserID];
    retval.userName = [packed objectForKey:kUserName];
    retval.completed = [packed objectForKey:kCompleted];
    
    NSMutableArray *newFiles = [[NSMutableArray alloc] init];
    for (id packedFile in [packed objectForKey:kFiles]) {
        Audio *file = [[Audio alloc] init];
        file.word = retval;
        if ([packedFile isKindOfClass:[NSString class]]) // backwards compatability
            file.fileCode = packedFile;
        else if ([packedFile isKindOfClass:[NSNumber class]]) // backwards compatability
            file.fileID = packedFile;
        else if ([packedFile isKindOfClass:[NSDictionary class]]) {
            file.fileID = [packedFile objectForKey:@"fileID"];
            file.fileCode = [packedFile objectForKey:@"fileCode"];
        } else
            NSLog(@"Malformed word file %@ with class %@", file, [file class]);
        [newFiles addObject:file];
    }
    retval.files = newFiles;
    return retval;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    if (self.wordID)
        [retval setObject:self.wordID forKey:kWordID];
    if (self.wordCode)
        [retval setObject:self.wordCode forKey:kWordCode];
    if (self.languageTag)
        [retval setObject:self.languageTag forKey:kLanguageTag];
    if (self.name)
        [retval setObject:self.name forKey:kName];
    if (self.detail)
        [retval setObject:self.detail forKey:kDetail];
    if (self.userName)
        [retval setObject:self.userName forKey:kUserName];
    if (self.userID)
        [retval setObject:self.userID forKey:kUserID];
    NSMutableArray *packedFiles = [[NSMutableArray alloc] init];
    for (Audio *file in self.files) {
        NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
        if (file.fileID)
            [fileDict setObject:file.fileID forKey:kFileID];
        if (file.fileCode)
            [fileDict setObject:file.fileCode forKey:kFileCode];
        [packedFiles addObject:fileDict];
    }
    [retval setObject:packedFiles forKey:kFiles];
    if (self.completed && self.completed.boolValue)
        [retval setObject:self.completed forKey:kCompleted];
    return retval;
}

+ (Word *)wordWithJSON:(NSData *)data
{
    NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [Word wordWithDictionary:packed];
}

- (NSData *)JSON
{
    return [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:nil];
}

@end
