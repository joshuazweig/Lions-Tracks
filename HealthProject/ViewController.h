//
//  ViewController.h
//  HealthProject
//
//  Created by Shiv Sakhuja on 4/1/15.
//  Copyright (c) 2015 Shiv Sakhuja. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
#import "JBChartView.h"
#import "JBBarChartView.h"
#import "JBLineChartView.h"

@interface ViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UIPickerView *agePickerView;
    IBOutlet UIPickerView *heightPickerView;
    IBOutlet UIPickerView *weightPickerView;
    
    IBOutlet UIView *basicInfoView;
    IBOutlet UIView *additionalInfoView;
    
    IBOutlet UIImageView *blurImage;
    IBOutlet UIView *headerView;
    IBOutlet UIImageView *mainImage;
    
    IBOutlet UITableView *tableView;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UILabel *loading;
    IBOutlet UIView *loadingView;
    
    IBOutlet UILabel *detailDayValue;
    IBOutlet UILabel *detailDayMoreLessText;
    IBOutlet UILabel *detailWeekMoreLessText;
    IBOutlet UILabel *detailDateText;
    IBOutlet UILabel *detailUserDataValue;
    IBOutlet UILabel *detailDataType;
    IBOutlet UILabel *detailCUDataValue;
    IBOutlet UIImageView *detailDataIcon;
    
    IBOutlet UIView *detailView;
    IBOutlet UIView *mainView;
    IBOutlet UIView *sideView;
    IBOutlet UIView *infoView;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *activityLevelSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sleepSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *healthSegmentedControl;

@property (nonatomic, retain) HKHealthStore *healthStore;

-(IBAction)genderValueChanged:(id)sender;
-(IBAction)activityLevelValueChanged:(id)sender;
-(IBAction)sleepValueChanged:(id)sender;
-(IBAction)healthValueChanged:(id)sender;
-(IBAction)backToMainView:(id)sender;
- (IBAction)showSideView:(id)sender;
- (IBAction)showInfo:(id)sender;
- (IBAction)hideSideView:(id)sender;
- (IBAction)hideInfoView:(id)sender;


@end

