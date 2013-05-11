//
//  Audio.h
//  Echo
//
//  Created by Will Entriken on 5/8/13.
//
//

#import <Foundation/Foundation.h>
#import "Word.h"

@interface Audio : NSObject
@property (strong, nonatomic) NSNumber *fileID;
@property (strong, nonatomic) NSString *fileCode;
@property (readonly, strong, nonatomic) NSString *filePath;
@property (weak, nonatomic) Word *word;
- (BOOL)fileExistsOnDisk;
@end
