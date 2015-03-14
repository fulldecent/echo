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
        _files = @[];
    return _files;
}

- (Audio *)fileWithCode:(NSString *)fileCode
{
    for (Audio *file in self.files)
        if ([file.fileCode isEqualToString:fileCode])
            return file;
    return nil;
}

- (NSURL *)fileURL
{
    if (!self.lesson.fileURL)
        return [NSURL fileURLWithPath:NSTemporaryDirectory()]; // a practice word
    if (self.wordID)
        return [self.lesson.fileURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)[self.wordID integerValue]]];
    else
        return [self.lesson.fileURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.wordCode]];
}

+ (Word *)wordWithDictionary:(NSDictionary *)packed
{
    Word *retval = [[Word alloc] init];
    NSAssert([packed isKindOfClass:[NSDictionary class]], @"trying to deserialize Word from something other than a dictionary");
    retval.wordID = packed[kWordID];
    if (packed[kWordCode])
        retval.wordCode = packed[kWordCode];
    else
        retval.wordCode = [NSString string];
    retval.languageTag = packed[kLanguageTag];
    retval.name = packed[kName];
    if ([packed[kDetail] isKindOfClass:[NSString class]])
        retval.detail = packed[kDetail];
    else if ([packed[kDetail] isKindOfClass:[NSDictionary class]]) // Backwards compatibility <= 1.0.9
        retval.detail = ((NSDictionary *)packed[kDetail])[retval.languageTag];
    retval.userID = packed[kUserID];
    retval.userName = packed[kUserName];
    retval.completed = packed[kCompleted];
    
    NSMutableArray *newFiles = [[NSMutableArray alloc] init];
    for (id packedFile in packed[kFiles]) {
        Audio *file = [[Audio alloc] init];
        file.word = retval;
        if ([packedFile isKindOfClass:[NSString class]]) // backwards compatability
            file.fileCode = packedFile;
        else if ([packedFile isKindOfClass:[NSNumber class]]) // backwards compatability
            file.fileID = packedFile;
        else if ([packedFile isKindOfClass:[NSDictionary class]]) {
            file.fileID = packedFile[@"fileID"];
            file.fileCode = packedFile[@"fileCode"];
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
        retval[kWordID] = self.wordID;
    if (self.wordCode)
        retval[kWordCode] = self.wordCode;
    if (self.languageTag)
        retval[kLanguageTag] = self.languageTag;
    if (self.name)
        retval[kName] = self.name;
    if (self.detail)
        retval[kDetail] = self.detail;
    if (self.userName)
        retval[kUserName] = self.userName;
    if (self.userID)
        retval[kUserID] = self.userID;
    NSMutableArray *packedFiles = [[NSMutableArray alloc] init];
    for (Audio *file in self.files) {
        NSMutableDictionary *fileDict = [[NSMutableDictionary alloc] init];
        if (file.fileID)
            fileDict[kFileID] = file.fileID;
        if (file.fileCode)
            fileDict[kFileCode] = file.fileCode;
        [packedFiles addObject:fileDict];
    }
    retval[kFiles] = packedFiles;
    if (self.completed && self.completed.boolValue)
        retval[kCompleted] = self.completed;
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
