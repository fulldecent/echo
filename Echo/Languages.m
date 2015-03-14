//
//  PHORLanguages.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Languages.h"

@interface Languages()
@end

@implementation Languages

+ (NSArray *)languages // [{tag:TAG,lang:LANG},...]
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"plist"];
    return [[NSArray alloc] initWithContentsOfFile:path];
}

+ (NSString *)nativeDescriptionForLanguage:(NSString *)langTag
{
    for (NSDictionary *lang in [self languages]) {
        if ([(NSString *)lang[@"tag"] isEqualToString:langTag])
            return lang[@"nativeName"];
    }

    return nil;
}

+ (NSArray *)sortedListOfLanguages:(NSArray *)langTags
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    
    for (NSDictionary *lang in [Languages languages]) 
        if ([langTags containsObject:lang[@"tag"]])
            [retval addObject:(NSString *)lang[@"tag"]];
    return retval;
}

@end
