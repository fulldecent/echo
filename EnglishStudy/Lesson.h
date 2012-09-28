//
//  lesson.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Lesson : NSObject <NSCopying>
@property (strong, nonatomic) NSNumber *lessonID;
@property (strong, nonatomic) NSString *lessonCode;
@property (strong, nonatomic) NSString *languageTag;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSDictionary *detail;
@property (strong, nonatomic) NSNumber *version;
@property (strong, nonatomic) NSNumber *serverVersion;
@property (strong, nonatomic) NSArray *words;
@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *userName;

@property (strong, nonatomic) NSNumber *submittedLikeVote; // (BOOL)
@property (readonly, strong, nonatomic) NSString *filePath;

+ (Lesson *)lessonWithJSON:(NSData *)data;
- (NSData *)JSON;
- (void)setToLesson:(Lesson *)lesson;
- (void)removeStaleFiles;
- (NSArray *)listOfMissingFiles; // return: [{"word":Word *,"fileID":NSNumber *},...]

- (BOOL)isOlderThanServer;
- (BOOL)isNewerThanServer;
- (BOOL)isUsable;
- (BOOL)isEditable;
- (BOOL)isShared;

@end
