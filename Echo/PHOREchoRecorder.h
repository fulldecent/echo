//
//  PHORRecordModel.h
//  Test Record 2
//
//  Created by Will Entriken on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PHOREchoRecorder;

@protocol PHOREchoRecorderDelegate
- (void) recording:(PHOREchoRecorder *)recorder didFinishSuccessfully:(BOOL)success;
@end

@interface PHOREchoRecorder : NSObject
- (id)initWithAudioDataAtFilePath:(NSString *)filePath;
@property (strong, nonatomic) NSNumber *microphoneLevel;
@property (strong, nonatomic) NSNumber *duration;
@property (strong, nonatomic) NSNumber *pan;
@property (nonatomic) BOOL audioWasModified;
@property (weak, nonatomic) id <PHOREchoRecorderDelegate> delegate;
- (void)record;
- (void)stopRecordingAndKeepResult:(BOOL)save;
- (void)playback;
- (void)reset;
- (NSString *)getAudioDataFilePath;
@end
