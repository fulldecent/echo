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

+ (NSString *)makeUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

- (NSString *)fileCode
{
    if (!_fileCode)
        _fileCode = [Audio makeUUID];
    return _fileCode;
}

- (NSString *)filePath
{
    if (self.fileID.intValue)
        return [self.word.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [self.fileID integerValue]]];
    else
        return [self.word.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.fileCode]];
}

- (BOOL)fileExistsOnDisk
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:self.filePath];
}
@end
