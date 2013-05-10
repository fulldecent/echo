//
//  Audio.m
//  Echo
//
//  Created by Will Entriken on 5/8/13.
//
//

#import "Audio.h"

@implementation Audio
@synthesize fileID = _fileID;
@synthesize fileCode = _fileCode;
@synthesize filePath = _filePath;

- (BOOL)fileExistsOnDisk
{
    return self.filePath;
}

@end
