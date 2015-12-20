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
@property (strong, nonatomic) NSNumber *serverTimeOfLastCompletedSync;
@property (nonatomic) BOOL localChangesSinceLastSync;
@property (nonatomic) BOOL remoteChangesSinceLastSync;
@property (strong, nonatomic) NSArray *words;
@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSNumber *numLikes;
@property (strong, nonatomic) NSNumber *numFlags;
@property (strong, nonatomic) NSNumber *numUsers;

@property (readonly, strong, nonatomic) NSURL *fileURL;

- (void)setToLesson:(Lesson *)lesson;
- (void)removeStaleFiles;
- (NSArray *)listOfMissingFiles; // return: [{"word":Word *,"audio":Audio *},...]
- (NSNumber *)portionComplete;
- (Word *)wordWithCode:(NSString *)wordCode;

- (BOOL)isByCurrentUser;
- (BOOL)isShared;

+ (Lesson *)lessonWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
+ (Lesson *)lessonWithJSON:(NSData *)data;
- (NSData *)JSON;

@end
