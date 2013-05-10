//
//  Word.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Word : NSObject <NSCopying>
@property (strong, nonatomic) NSNumber *wordID;
@property (strong, nonatomic) NSString *wordCode;
@property (strong, nonatomic) NSString *languageTag;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *detail;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSArray *files; // [Audio, ...]

// client side data
@property (strong, nonatomic) NSNumber *completed;

+ (Word *)wordWithJSON:(NSData *)data;
- (NSData *)JSON;
- (NSArray *)listOfMissingFiles; // [Audio, ...]

@end
