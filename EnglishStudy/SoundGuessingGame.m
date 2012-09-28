//
//  PHORSoundGuessingGame.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SoundGuessingGame.h"

@interface SoundGuessingGame()

// These are readonly publicly
@property (strong, nonatomic) NSArray *currentQuestion;
@property (strong, nonatomic) NSString *currentSound;
@property NSInteger correctAnswers;
@property NSInteger totalAnswers;
@property BOOL gameInProgress;

// These are private all the way
@property (strong, nonatomic) NSArray *setList;
@property (strong, nonatomic) NSDictionary *soundList;
@property NSInteger currentAnswerIndex;
- (void)shuffleQuestions;

@end


@implementation SoundGuessingGame

@synthesize filter = _filter;
@synthesize currentQuestion = _currentQuestion;
@synthesize currentSound = _currentSound;
@synthesize correctAnswers = _correctAnswers;
@synthesize totalAnswers = _totalAnswers;
@synthesize gameInProgress = _gameInProgress;
@synthesize setList = _setList;
@synthesize soundList = _soundList;
@synthesize currentAnswerIndex = _currentAnswerIndex;

- (id)init
{
    self = [super init];
    if (self) {
        [self shuffleQuestions];
    }
    return self;
}

- (NSArray *)setList
{
    if (!_setList) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Sets" ofType:@"plist"];
        _setList = [[NSArray alloc] initWithContentsOfFile:path];
    }
    return _setList;
}

- (NSDictionary *)soundList
{
    if (!_soundList) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Sound List" ofType:@"plist"];
        _soundList = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    return _soundList;
}

- (NSInteger)makeGuess:(NSInteger)guess
{
    if (!self.currentQuestion) return -1;
    
#define NUMBER_OF_QUESTIONS_IN_GAME 10
    
    if (self.totalAnswers == NUMBER_OF_QUESTIONS_IN_GAME) {
        self.totalAnswers = 0;
        self.correctAnswers = 0;
    }
    
    NSInteger correctAnswer = self.currentAnswerIndex;
    self.totalAnswers++;
    if (guess == self.currentAnswerIndex) self.correctAnswers++;
    [self shuffleQuestions];
    
    if (self.totalAnswers == NUMBER_OF_QUESTIONS_IN_GAME)
        self.gameInProgress = NO;
    
    return correctAnswer;
}

- (void)shuffleQuestions 
{
    NSInteger chosenSetIndex = arc4random() % [self.setList count];
    self.currentQuestion = [self.setList objectAtIndex:chosenSetIndex];
    self.currentAnswerIndex = arc4random() % [self.currentQuestion count];
    
    NSString *currentAnswerString = [self.currentQuestion objectAtIndex:self.currentAnswerIndex];
    NSArray *optionsForAnswerSound = [self.soundList objectForKey:currentAnswerString];
    if ([self.filter length] > 0) {
        NSPredicate *containPred = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", self.filter];  
        optionsForAnswerSound = [optionsForAnswerSound filteredArrayUsingPredicate:containPred];
    }
    NSInteger chosenSoundIndex = arc4random() % [optionsForAnswerSound count];
    self.currentSound = [optionsForAnswerSound objectAtIndex:chosenSoundIndex];
    self.gameInProgress = YES;
} 

@end
