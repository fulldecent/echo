//
//  PHORLanguages.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Languages : NSObject
+ (NSArray *)languages;
+ (NSString *)nativeDescriptionForLanguage:(NSString *)langTag;
+ (NSArray *)sortedListOfLanguages:(NSArray *)langTags;
@end
