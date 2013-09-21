//
//  PHORRecordButton.h
//  Test Record 2
//
//  Created by Will Entriken on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIGlossyButton.h"

@interface PHOREchoRecordButton : UIGlossyButton

enum PHORRecordButtonState {
    PHORRecordButtonStateRecord,
    PHORRecordButtonStatePlayback,
    PHORRecordButtonStateConfirmDelete,
    PHORRecordButtonStatePlaybackOnly
};
@property (nonatomic) enum PHORRecordButtonState state;
@property (nonatomic) float value; // 0 to 1
// emits touch events as well as UIControlEventValueChanged when user uses touch to change state

@end
