//
//  PHORRecordButton.m
//  Test Record 2
//
//  Created by Will Entriken on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PHOREchoRecordButton.h"
#import "F3BarGauge.h"

@interface PHOREchoRecordButton()
@property (strong, nonatomic) F3BarGauge *ledLevel;
@property (strong, nonatomic) UIButton *deleteButton;
@end

@implementation PHOREchoRecordButton
@synthesize value = _value;
@synthesize state = _state;
@synthesize ledLevel = _ledLevel;
@synthesize deleteButton = _deleteButton;

- (void)setValue:(float)value
{
    self.ledLevel.value = value;
    _value = value;
}

- (void)setState:(enum PHORRecordButtonState)state
{
    [self.ledLevel removeFromSuperview];
    [self.titleLabel removeFromSuperview];
    [self.deleteButton removeFromSuperview];
    [self removeTarget:self action:@selector(ignoreDelete) forControlEvents:UIControlEventTouchUpInside];

    if (state == PHORRecordButtonStateRecord) {
        [self addSubview:self.ledLevel];
        [self setImage:[UIImage imageNamed:@"microphone icon"] forState:UIControlStateNormal];
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    } else if (state == PHORRecordButtonStatePlayback || state == PHORRecordButtonStatePlaybackOnly) {
        [self addSubview:self.titleLabel];
        [self setImage:[UIImage imageNamed:@"speaker icon"] forState:UIControlStateNormal];
        
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    } else if (state == PHORRecordButtonStateConfirmDelete) {
        [self setImage:[UIImage imageNamed:@"speaker icon"] forState:UIControlStateNormal];
        [self addSubview:self.titleLabel];
        [self addSubview:self.deleteButton];
        
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self addTarget:self action:@selector(ignoreDelete) forControlEvents:UIControlEventTouchUpInside];
    } 
    _state = state;
}

- (F3BarGauge *)ledLevel
{
    if (!_ledLevel) {
        CGRect ledFrame = CGRectMake(self.imageView.frame.size.width + self.imageEdgeInsets.left/2 + self.imageEdgeInsets.right/2,
                                     self.frame.size.height/4,
                                     self.frame.size.width - self.imageView.frame.size.width - self.imageEdgeInsets.left - self.imageEdgeInsets.right,
                                     self.frame.size.height/2);
        _ledLevel = [[F3BarGauge alloc] initWithFrame:ledFrame];
        _ledLevel.numBars = 12;
        _ledLevel.outerBorderColor = [UIColor clearColor];
        _ledLevel.innerBorderColor = [UIColor clearColor];
        _ledLevel.backgroundColor = [UIColor clearColor];
        _ledLevel.userInteractionEnabled = NO;
        _ledLevel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return _ledLevel;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        CGRect frame = CGRectMake(self.frame.size.width - 12 - 100,
                                  self.frame.size.height/4,
                                  100, 
                                  self.frame.size.height/2);
        _deleteButton = [[UIButton alloc] initWithFrame:frame];
        
        [_deleteButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"]
                                               stretchableImageWithLeftCapWidth:8.0f
                                               topCapHeight:0.0f]
                                            forState:UIControlStateNormal];
        
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _deleteButton.titleLabel.shadowColor = [UIColor lightGrayColor];
        _deleteButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
        [_deleteButton setTitle:@"Reset" forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (void)setup
{
    self.state = PHORRecordButtonStateRecord;
    UISwipeGestureRecognizer *horizontal = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe)];
    horizontal.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:horizontal];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)handleSwipe
{
    if (self.state == PHORRecordButtonStatePlayback)
        self.state = PHORRecordButtonStateConfirmDelete;
}

- (void)reset
{
    self.state = PHORRecordButtonStateRecord;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)ignoreDelete
{
    self.state = PHORRecordButtonStatePlayback;
}

@end
