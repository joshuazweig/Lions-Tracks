//
//  CustomCell.h
//  HealthProject
//
//  Created by Shiv Sakhuja on 04/29/15.
//  Copyright (c) 2015 Shiv Sakhuja. All rights reserved.
//

#import "CustomCell.h"
#import <pop/POP.h>

@implementation CustomCell

@synthesize cellView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    cellView.layer.masksToBounds = NO;
    cellView.layer.shadowColor = [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.3] CGColor];
    cellView.layer.shadowOpacity = 0.0;
    cellView.layer.shadowOffset = CGSizeMake(0, 1);
    cellView.layer.shadowRadius = 1.0;
}
//
//- (void)setFrame:(CGRect)frame {
//    frame.origin.y += 4;
//    frame.size.height -= 2 * 4;
//    [super setFrame:frame];
//}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (self.highlighted) {
        POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        scaleAnimation.duration = 0.1;
        scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        [self.userDataValue pop_addAnimation:scaleAnimation forKey:@"scalingUp"];
        
        
        
    } else {
        POPSpringAnimation *sprintAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        sprintAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
        sprintAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
        sprintAnimation.springBounciness = 20.f;
        [self.userDataValue pop_addAnimation:sprintAnimation forKey:@"springAnimation"];
    }
}

@end
