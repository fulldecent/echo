//
//  Word.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lesson.h"

@interface Word : NSObject <NSCopying>
@property (strong, nonatomic) NSNumber *wordID;
@property (strong, nonatomic) NSString *wordCode;
@property (strong, nonatomic) NSString *languageTag;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *nativeDetail;
@property (strong, nonatomic) NSDictionary *detail;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSArray *files; // NSArray of NSStrings of file basenames including extensions

+ (Word *)wordWithJSON:(NSData *)data;
- (NSData *)JSON;
- (NSArray *)listOfMissingFiles; // return: [NSNumber *,...]

@end
