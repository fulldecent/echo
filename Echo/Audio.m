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

- (NSString *)fileCode
{
    if (!_fileCode)
        _fileCode = [[NSUUID UUID] UUIDString];
    return _fileCode;
}

- (NSString *)filePath
{
    if (self.fileID.intValue)
        return [self.word.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)[self.fileID integerValue]]];
    else
        return [self.word.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.fileCode]];
}

- (BOOL)fileExistsOnDisk
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:self.filePath];
}
@end
