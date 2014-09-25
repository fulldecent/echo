//
//  Word.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Lesson;
@class Audio;

@interface Word : NSObject

// Synched with server
@property (strong, nonatomic) NSNumber *wordID;
@property (strong, nonatomic) NSString *wordCode;
@property (strong, nonatomic) NSString *languageTag;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *detail;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSArray *files; // [Audio, ...]

// Local data
@property (weak, nonatomic) Lesson *lesson;
@property (strong, nonatomic) NSNumber *completed; // client side data

- (NSURL *)fileURL;
- (NSArray *)listOfMissingFiles; // [Audio, ...]
- (Audio *)fileWithCode:(NSString *)fileCode;

+ (Word *)wordWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
+ (Word *)wordWithJSON:(NSData *)data;
- (NSData *)JSON;

@end
