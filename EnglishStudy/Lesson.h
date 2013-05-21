//
//  lesson.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Word;

@interface Lesson : NSObject
@property (strong, nonatomic) NSNumber *lessonID;
@property (strong, nonatomic) NSString *lessonCode;
@property (strong, nonatomic) NSString *languageTag;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *detail;
@property (strong, nonatomic) NSNumber *version;
@property (strong, nonatomic) NSNumber *serverVersion;
@property (strong, nonatomic) NSArray *words;
@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSNumber *numLikes;
@property (strong, nonatomic) NSNumber *numFlags;
@property (strong, nonatomic) NSNumber *numUsers;
@property (strong, nonatomic) NSDictionary *translations; // {"en":Lesson *,...}

@property (strong, nonatomic) NSNumber *submittedLikeVote; // (BOOL)
@property (readonly, strong, nonatomic) NSString *filePath;

- (void)setToLesson:(Lesson *)lesson;
- (void)removeStaleFiles;
- (NSArray *)listOfMissingFiles; // return: [{"word":Word *,"audio":Audio *},...]
- (NSNumber *)portionComplete;
- (Word *)wordWithCode:(NSString *)wordCode;
- (Word *)wordWithCode:(NSString *)wordCode translatedTo:(NSString *)langTag;

- (BOOL)isOlderThanServer;
- (BOOL)isNewerThanServer;
- (BOOL)isByCurrentUser;
- (BOOL)isShared;

+ (Lesson *)lessonWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
+ (Lesson *)lessonWithJSON:(NSData *)data;
- (NSData *)JSON;

@end
