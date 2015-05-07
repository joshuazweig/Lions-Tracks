//
//  CustomCell.h
//  HealthProject
//
//  Created by Shiv Sakhuja on 04/29/15.
//  Copyright (c) 2015 Shiv Sakhuja. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomCell : UITableViewCell {
    
}

@property (weak, nonatomic) IBOutlet UIView *cellView;

@property (weak, nonatomic) IBOutlet UILabel *userDataValue;
@property (weak, nonatomic) IBOutlet UILabel *userDataType;
@property (weak, nonatomic) IBOutlet UILabel *CUDataValue;
@property (weak, nonatomic) IBOutlet UILabel *CUDataType;

@property (weak, nonatomic) IBOutlet UIImageView *healthDataIcon;

@end
