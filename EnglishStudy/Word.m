//
//  Word.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Word.h"

@interface Word()
+ (NSString *)makeUUID;
@end

@implementation Word
@synthesize wordID = _wordID;
@synthesize wordCode = _wordCode;
@synthesize languageTag = _languageTag;
@synthesize name = _name;
@synthesize detail = _detail;
@synthesize userID = _userID;
@synthesize userName = _userName;
@synthesize files = _files;
@synthesize nativeDetail = _nativeDetail;

#define kLanguageTag @"languageTag"
#define kName @"name"
#define kDetail @"detail"
#define kWordID @"wordID"
#define kWordCode @"wordCode"
#define kUserID @"userID"
#define kUserName @"userName"
#define kFiles @"files"

+ (Word *)wordWithJSON:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    Word *retval = [[Word alloc] init];
    if (![packed isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Initialize Word: poor JSON");
        return nil;
    }
    
    retval.wordID = [packed objectForKey:kWordID];
    if ([packed objectForKey:kWordCode])
        retval.wordCode = [packed objectForKey:kWordCode];
    else
        retval.wordCode = [NSString string];
    retval.languageTag = [packed objectForKey:kLanguageTag];
    retval.name = [packed objectForKey:kName];
    for (id str in [packed objectForKey:kDetail]) {
        if (![str isKindOfClass:[NSString class]]) {
            NSLog(@"Word detail error with class %@", [str class]);
            return nil;
        }
    }
    retval.detail = [packed objectForKey:kDetail];
    retval.userID = [packed objectForKey:kUserID];
    retval.userName = [packed objectForKey:kUserName];

    NSMutableArray *newFiles = [[NSMutableArray alloc] init];
    for (id file in [packed objectForKey:kFiles]) {
        if ([file isKindOfClass:[NSString class]])
            [newFiles addObject:file];
        else if ([file isKindOfClass:[NSNumber class]])
            [newFiles addObject:[NSString stringWithFormat:@"%d", [(NSNumber *)file integerValue]]];
        else
            NSLog(@"Malformed word file %@ with class %@", file, [file class]);
    }
    retval.files = newFiles;
    return retval;
}

-(NSData *)JSON
{
    NSMutableDictionary *wordDict = [[NSMutableDictionary alloc] init];
    if (self.wordID)
        [wordDict setObject:self.wordID forKey:kWordID];
    if (self.wordCode)
        [wordDict setObject:self.wordCode forKey:kWordCode];
    if (self.languageTag)
        [wordDict setObject:self.languageTag forKey:kLanguageTag];
    if (self.name)
        [wordDict setObject:self.name forKey:kName];
    if (self.detail)
        [wordDict setObject:self.detail forKey:kDetail];
    if (self.userName)
        [wordDict setObject:self.userName forKey:kUserName];
    if (self.userID)
        [wordDict setObject:self.userID forKey:kUserID];
    if (self.files)
        [wordDict setObject:self.files forKey:kFiles];
    
    NSError *error = nil;
    return [NSJSONSerialization dataWithJSONObject:wordDict options:0 error:&error];
}

- (NSArray *)listOfMissingFiles
{
#warning this is only partially implemented, it fails if self.files includes Codes
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    for (NSString *str in self.files) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        [retval addObject:[f numberFromString:str]];
    }
    return self.files;
}


+ (NSString *)makeUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

- (NSString *)wordCode
{
    if (!_wordCode)
        _wordCode = [Word makeUUID];
    return _wordCode;
}

- (NSArray *)files
{
    if (!_files)
        _files = [NSArray array];
    return _files;
}

- (void)setNativeDetail:(NSString *)nativeDetail
{
    _nativeDetail = nativeDetail;
    if (nativeDetail && _languageTag) {
        if (_detail) {
            NSMutableDictionary *tmp = [_detail mutableCopy];
            [tmp setObject:nativeDetail forKey:self.languageTag];
            _detail = tmp;
        } else {
            _detail = [NSDictionary dictionaryWithObject:nativeDetail forKey:self.languageTag];
        }
    }
}

- (NSString *)nativeDetail
{
    return [self.detail objectForKey:self.languageTag];
}

- (void)setLanguageTag:(NSString *)languageTag
{
    _languageTag = languageTag;
    [self setNativeDetail:_nativeDetail];
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    Word *copy = [[Word alloc] init];
    copy.wordCode = [self.wordCode copy];
    copy.name = [self.name copy];
    copy.detail = [self.detail copy];
    copy.languageTag = [self.languageTag copy]; // order is important here
    copy.nativeDetail = [self.nativeDetail copy];
    copy.files = [[NSArray alloc] initWithArray:self.files copyItems:YES];
    return copy;
}

@end
