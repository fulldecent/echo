//
//  FDRightDetailWithTextFieldCell.m
//  Echo
//
//  Created by William Entriken on 2/6/14.
//
//

#import "FDRightDetailWithTextFieldCell.h"

@implementation FDRightDetailWithTextFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
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

- (void)setup
{
    self.detailTextLabel.hidden = YES;
    [[self.contentView viewWithTag:3] removeFromSuperview];
    self.textField = [[UITextField alloc] init];
    self.textField.tag = 3;
    self.textField.textAlignment = NSTextAlignmentRight;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.textField];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textField.frame = self.detailTextLabel.frame;
}

@end
