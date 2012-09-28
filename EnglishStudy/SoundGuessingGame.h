//
//  PHORSoundGuessingGame.h
//  EnglishStudy
//
//  Created by Will Entriken on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundGuessingGame : NSObject

- (NSInteger)makeGuess:(NSInteger)guess;

@property (strong, nonatomic) NSString *filter;
@property (strong, nonatomic, readonly) NSArray *currentQuestion;
@property (strong, nonatomic, readonly) NSString *currentSound;
@property (readonly) NSInteger correctAnswers;
@property (readonly) NSInteger totalAnswers;
@property (readonly) BOOL gameInProgress;

@end
