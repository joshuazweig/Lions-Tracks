//
//  ViewController.m
//  HealthProject
//
//  Created by Shiv Sakhuja on 4/1/15.
//  Copyright (c) 2015 Shiv Sakhuja. All rights reserved.
//

#import "ViewController.h"
#import "CustomCell.h"
#import <POP/POP.h>
#import <HealthKit/HealthKit.h>
#import <SSKeychain/SSKeychain.h>

@interface ViewController () <JBBarChartViewDelegate, JBBarChartViewDataSource>

@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *activity;
@property (nonatomic, retain) NSString *sleep;
@property (nonatomic, retain) NSString *health;
@property (nonatomic, retain) NSString *deviceID;
@property (nonatomic, retain) NSString *lastPosted;
@property (nonatomic, retain) NSString *selectedDataType;
@property (nonatomic, retain) NSString *selectedDataValue;
@property (nonatomic, retain) NSString *selectedDataUnit;
@property (nonatomic, retain) NSString *selectedCUDataValue;
@property (nonatomic, strong) JBBarChartView *barChartView;

@end

NSString *ROOT_ADDRESS = @"http://lions-tracks.herokuapp.com/";    //Database Root Address
NSString *KEYCHAIN_SERVICE = @"DeviceDetails";                     //Keychain for Device Data
NSString *KEYCHAIN_SERVICE_POST = @"PostDetails";
int CONSTANT_VALUE = 16;

int age;
int height;
int weight;
BOOL isCleared;
NSArray *pastUserValues;
NSArray *pastCUValues;

NSMutableArray *healthData;
NSDictionary *imageDictionary;

@implementation ViewController

@synthesize genderSegmentedControl, healthSegmentedControl, activityLevelSegmentedControl, sleepSegmentedControl, barChartView, selectedDataType, selectedDataValue, selectedDataUnit, selectedCUDataValue;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [headerView setClipsToBounds:YES];
    [self addLoadingElements];
    pastUserValues = [NSArray arrayWithObjects:@"10.0", @"20.0",@"15.0", @"22.0",@"17.0", @"12.0", @"9.0", @"0.0", nil];
    pastCUValues = [NSArray arrayWithObjects:@"13.0", @"11.0",@"25.0", @"18.0",@"17.0", @"18.0", @"19.0", @"0.0", nil];
    
}

-(void)addLoadingElements {
    loadingView = [[UIView alloc] initWithFrame:CGRectMake(110, 234, 100, 100)];
    [loadingView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.1 blue:0.3 alpha:0.5]];
    [loadingView setAlpha:1.0];
    [[loadingView layer] setCornerRadius:10.0];
    [mainView addSubview:loadingView];
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.center = CGPointMake(50, 40);
    spinner.hidesWhenStopped = YES;
    
    loading = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 80, 20)];
    [loading setText:[NSString stringWithFormat:@"Loading.."]];
    [loading setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17]];
    [loading setTextAlignment:NSTextAlignmentCenter];
    [loading setTextColor:[UIColor whiteColor] ];
    
    [loadingView addSubview:spinner];
    [loadingView addSubview:loading];
    [spinner startAnimating];
}

-(void)viewWillAppear:(BOOL)animated {
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setDefaults];
    [self routineCheck];
}

-(void)firstTimeHealthKitCheck {
    NSLog(@"firstTimeHealthKitCheck running");
    if ([self.restorationIdentifier isEqualToString:@"main"]) {
        [self performSegueWithIdentifier:@"MainToInitial" sender:self];
    }
    
    //If Health Kit is available on the device
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        //Ask for Permission
        
        HKHealthStore *healthStore = [[HKHealthStore alloc] init];
        
        // Share body mass, height and body mass index
        NSSet *shareObjectTypes = [self shareTypes];
        
        // Read date of birth, biological sex and step count
        NSSet *readObjectTypes  = [self readTypes];
        
        // Request access
        [healthStore requestAuthorizationToShareTypes:shareObjectTypes
                                            readTypes:readObjectTypes
                                           completion:^(BOOL success, NSError *error) {
                                               
                                               if(success == YES)
                                               {
                                                   // ...
                                               }
                                               else
                                               {
                                                   // Determine if it was an error or if the
                                                   // user just canceld the authorization request
                                               }
                                               
                                           }];
        
    }
    else {
        //Alert the user
        UIAlertView *noHealthKitAlert = [[UIAlertView alloc] initWithTitle:@"Health Data Unavailable" message:@"Sorry! Health data is not available on your device!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [noHealthKitAlert show];
        [self performSegueWithIdentifier:@"InitialToUnavailable" sender:self];
    }
    
    [self showBasicInfo:nil];
    
}

-(NSSet *)shareTypes {
    // Share body mass, height and body mass index
    NSSet *shareObjectTypes = [NSSet setWithObjects:
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
                               nil];
    return shareObjectTypes;
}

-(NSSet *)readTypes {
    NSSet *readObjectTypes  = [NSSet setWithObjects:
                               //                               [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
                               //                               [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned],
                               nil];
    
    return readObjectTypes;
}

-(void)routineCheck {
    //    For testing default screen
    //        [self firstTimeHealthKitCheck];
    
    //For testing
    if (!isCleared) {
        [self clearKeychain];
    }
    
    //If Keychain, then run
    NSArray *keychainArray = [SSKeychain accountsForService:KEYCHAIN_SERVICE];
    if ([keychainArray count] > 0 && [self validateAuthorization]) {
        NSString *device = [keychainArray[0] objectForKey:@"acct"];
        self.deviceID = [SSKeychain passwordForService:KEYCHAIN_SERVICE account:device];
        [self getUserData:self.deviceID];
        NSLog(@"Device ID (From Keychain) %@", self.deviceID);
    }
    //If no keychain or healthkit not authorized, perform First Time Check
    else {
        [self firstTimeHealthKitCheck];
    }
    
    healthData = [[NSMutableArray alloc] init];
    imageDictionary = [NSDictionary dictionaryWithObjects:@[@"heart_white.png", @"footsteps.png", @"fire.png", @"cycling.png", @"walking.png", @"stairs.png", @"sleep.png"] forKeys:@[@"heart_rate", @"steps", @"active_calories", @"distance_cycling", @"distance_walking_running", @"flights_climbed", @"sleep"]];
    
}

-(void)clearKeychain {
    SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
    
    NSArray *accounts = [query fetchAll:nil];
    
    for (id account in accounts) {
        
        SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
        
        query.service = KEYCHAIN_SERVICE;
        query.account = [account valueForKey:@"acct"];
        
        [query deleteItem:nil];
        
    }
    isCleared = YES;
}

-(BOOL)validateAuthorization {
    for (HKObjectType *hkObj in [self readTypes]) {
        if ([self.healthStore authorizationStatusForType:hkObj] != 0) {
            NSLog(@"authorization for %@ is %ld", hkObj,(long)[self.healthStore authorizationStatusForType:hkObj]);
            return FALSE;
        }
    }
    return TRUE;
}

-(NSArray *)getStartEndDates {
    // Set your start and end date for your query of interest
    NSDate *endDate = [NSDate date];
    int daysToAdd = -1;
    
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daysToAdd];
    
    // create a calendar
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDate *startDate = [gregorian dateByAddingComponents:components toDate:endDate options:0];
    NSLog(@"Start Date: %@ \n End Date: %@", startDate, endDate);
    
    NSArray *dates = [[NSArray alloc] initWithObjects:startDate, endDate, nil];
    return dates;
}

-(void)getUserData:(NSString *)identification {
    HKHealthStore *healthStore = [[HKHealthStore alloc] init];
    
    NSDate *startDate = [[self getStartEndDates] objectAtIndex:0];
    NSDate *endDate = [[self getStartEndDates] objectAtIndex:1];
    
    /****** START STEP COUNT *******/
    
    // Use the sample type for step count
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // Create a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                if(!error && results)
                                                                {
                                                                    int steps = 0;
                                                                    NSString *stepValue;
                                                                    for(HKQuantitySample *samples in results) {
                                                                        HKQuantity *quantity = samples.quantity;
                                                                        NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                                        stepValue = [qtyString stringByReplacingOccurrencesOfString:@" count" withString:@""];
                                                                        steps += [stepValue integerValue];
                                                                    }
                                                                    NSLog(@"%i Steps", steps);
                                                                    stepValue = [NSString stringWithFormat:@"%i", steps];
                                                                    if ([stepValue intValue] > 0) {
                                                                        [self addDataToArray:stepValue forDataType:@"steps" withUnits:@"count"];
                                                                    }
                                                                    
                                                                }
                                                            }];
    
    [healthStore executeQuery:sampleQuery];
    
    /****** END STEP COUNT *******/
    
    /****** START HEART RATE *******/
    
    sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                  predicate:predicate
                                                      limit:HKObjectQueryNoLimit
                                            sortDescriptors:@[sortDescriptor]
                                             resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                 
                                                 if(!error && results)
                                                 {
                                                     int heartRate = 0;
                                                     int timesMeasured = 0;
                                                     NSString *heartRateValue;
                                                     for(HKQuantitySample *samples in results) {
                                                         HKQuantity *quantity = samples.quantity;
                                                         NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                         heartRateValue = [qtyString stringByReplacingOccurrencesOfString:@" count/s" withString:@""];
                                                         double hrInBPS = [heartRateValue doubleValue];
                                                         heartRate += (hrInBPS * 60);
                                                         timesMeasured++;
                                                     }
                                                     if (timesMeasured != 0) {
                                                         NSLog(@"%i BPM", heartRate/timesMeasured);
                                                         heartRateValue = [NSString stringWithFormat:@"%i", heartRate/timesMeasured];
                                                     }
                                                     else {
                                                         heartRateValue = @"0";
                                                     }
                                                     
                                                     if ([heartRateValue intValue] > 0) {
                                                         [self addDataToArray:heartRateValue forDataType:@"heart_rate" withUnits:@"bpm"];
                                                     }
                                                 }
                                             }];
    
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    /****** END HEART RATE *******/
    
    /****** START ACTIVE CALORIES *******/
    
    sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                  predicate:predicate
                                                      limit:HKObjectQueryNoLimit
                                            sortDescriptors:@[sortDescriptor]
                                             resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                 
                                                 if(!error && results)
                                                 {
                                                     double activeCalories = 0.0;
                                                     NSString *calorieValue;
                                                     for(HKQuantitySample *samples in results) {
                                                         HKQuantity *quantity = samples.quantity;
                                                         NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                         calorieValue = [qtyString stringByReplacingOccurrencesOfString:@"" withString:@""];
                                                         double calories = [calorieValue doubleValue];
                                                         activeCalories += calories;
                                                     }
                                                     NSLog(@"%.2f Cal", activeCalories);
                                                     calorieValue = [NSString stringWithFormat:@"%.2f", activeCalories];
                                                     if ([calorieValue intValue] > 0) {
                                                         [self addDataToArray:calorieValue forDataType:@"active_calories" withUnits:@"cal"];
                                                     }
                                                     
                                                 }
                                             }];
    
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    /****** END ACTIVE CALORIES *******/
    
    /****** START CYCLING *******/
    
    sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    
    sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                  predicate:predicate
                                                      limit:HKObjectQueryNoLimit
                                            sortDescriptors:@[sortDescriptor]
                                             resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                 
                                                 if(!error && results)
                                                 {
                                                     double distanceCycling = 0.0;
                                                     NSString *value;
                                                     for(HKQuantitySample *samples in results) {
                                                         HKQuantity *quantity = samples.quantity;
                                                         NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                         value = [qtyString stringByReplacingOccurrencesOfString:@"" withString:@""];
                                                         double distance = [value doubleValue];
                                                         distanceCycling += distance;
                                                     }
                                                     NSLog(@"%.2f Cal", distanceCycling);
                                                     distanceCycling = distanceCycling / 1600;
                                                     value = [NSString stringWithFormat:@"%.2f", distanceCycling];
                                                     if ([value intValue] > 0) {
                                                         [self addDataToArray:value forDataType:@"distance_cycling" withUnits:@"miles"];
                                                     }
                                                 }
                                             }];
    
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    /****** END CYCLING *******/
    
    /****** START FLIGHTS CLIMBED *******/
    
    sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    
    sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                  predicate:predicate
                                                      limit:HKObjectQueryNoLimit
                                            sortDescriptors:@[sortDescriptor]
                                             resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                 
                                                 if(!error && results)
                                                 {
                                                     int flightsClimbed = 0;
                                                     NSString *value;
                                                     for(HKQuantitySample *samples in results) {
                                                         HKQuantity *quantity = samples.quantity;
                                                         NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                         value = [qtyString stringByReplacingOccurrencesOfString:@"" withString:@""];
                                                         double flights = [value doubleValue];
                                                         flightsClimbed += flights;
                                                     }
                                                     NSLog(@"%i flights climbed", flightsClimbed);
                                                     value = [NSString stringWithFormat:@"%i", flightsClimbed];
                                                     if ([value intValue] > 0) {
                                                         [self addDataToArray:value forDataType:@"flights_climbed" withUnits:@"count"];
                                                     }
                                                 }
                                             }];
    
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    /****** END FLIGHTS CLIMBED *******/
    
    /****** START DISTANCE WALKING RUNNING *******/
    
    sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                  predicate:predicate
                                                      limit:HKObjectQueryNoLimit
                                            sortDescriptors:@[sortDescriptor]
                                             resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                 
                                                 if(!error && results)
                                                 {
                                                     double distance = 0.0;
                                                     NSString *value;
                                                     for(HKQuantitySample *samples in results) {
                                                         HKQuantity *quantity = samples.quantity;
                                                         NSString *qtyString = [NSString stringWithFormat:@"%@", quantity];
                                                         value = [qtyString stringByReplacingOccurrencesOfString:@"" withString:@""];
                                                         double dist = [value doubleValue];
                                                         distance += dist;
                                                     }
                                                     NSLog(@"%.2f distance walked and run", distance);
                                                     value = [NSString stringWithFormat:@"%.2f", distance];
                                                     if ([value intValue] > 0) {
                                                         [self addDataToArray:value forDataType:@"distance_walking_running" withUnits:@"m"];
                                                     }
                                                 }
                                             }];
    
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    /****** END DISTANCE WALKING RUNNING *******/
    
    //    [self postAllHealthData];
    [self reloadTable];
}

-(void)setDefaults {
    [agePickerView selectRow:7 inComponent:0 animated:YES];
    [heightPickerView selectRow:55 inComponent:0 animated:YES];
    [weightPickerView selectRow:85 inComponent:0 animated:YES];
    
    [genderSegmentedControl setSelectedSegmentIndex:0];
    [activityLevelSegmentedControl setSelectedSegmentIndex:2];
    [sleepSegmentedControl setSelectedSegmentIndex:2];
    [healthSegmentedControl setSelectedSegmentIndex:2];
    
    [self genderValueChanged:self];
    [self activityLevelValueChanged:self];
    [self sleepValueChanged:self];
    [self healthValueChanged:self];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    //Age Picker
    if (pickerView.tag == 1) {
        return 122;
    }
    
    //Height Picker
    if (pickerView.tag == 2) {
        return 96;
    }
    
    //Weight Picker
    if (pickerView.tag == 3) {
        return 460;
    }
    
    return 100;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //Age Picker
    if (pickerView.tag == 1) {
        return [NSString stringWithFormat:@"%ld",(row+13)];
    }
    
    //Height Picker
    if (pickerView.tag == 2) {
        return [NSString stringWithFormat:@"%ld",(row+12)];
    }
    
    //Weight Picker
    if (pickerView.tag == 3) {
        return [NSString stringWithFormat:@"%ld",(row+40)];
    }
    
    return NULL;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    
    NSString *title = @"default";
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    //Age Picker
    if (pickerView.tag == 1) {
        title = [self pickerView:agePickerView titleForRow:row forComponent:0];
        attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    
    //Height Picker
    if (pickerView.tag == 2) {
        title = [self pickerView:heightPickerView titleForRow:row forComponent:0];
        attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    
    //Weight Picker
    if (pickerView.tag == 3) {
        title = [self pickerView:weightPickerView titleForRow:row forComponent:0];
        attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    
    
    return attString;
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //Age Picker
    if (pickerView.tag == 1) {
        age = (int) row + 13;
    }
    
    //Height Picker
    if (pickerView.tag == 2) {
        height = (int) row + 12;
    }
    
    //Weight Picker
    if (pickerView.tag == 3) {
        weight = (int) row + 40;
    }
}


-(IBAction)genderValueChanged:(id)sender {
    NSArray *GENDER_VALUES = [[NSArray alloc] initWithObjects:@"M", @"F", @"O", @"D", nil];
    _gender = [NSString stringWithFormat:[@"%@", GENDER_VALUES objectAtIndex:genderSegmentedControl.selectedSegmentIndex]];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(IBAction)activityLevelValueChanged:(id)sender {
    
    NSArray *ACTIVITY_VALUES = [[NSArray alloc] initWithObjects:@"1", @"2", @"3", @"4", @"5", nil];
    _activity = [NSString stringWithFormat:[@"%@", ACTIVITY_VALUES objectAtIndex:activityLevelSegmentedControl.selectedSegmentIndex]];
    self.view.backgroundColor = [UIColor whiteColor];
}

-(IBAction)sleepValueChanged:(id)sender {
    NSArray *SLEEP_VALUES = [[NSArray alloc] initWithObjects:@"1", @"3", @"5", @"7", @"9", nil];
    _sleep = [NSString stringWithFormat:[@"%@", SLEEP_VALUES objectAtIndex:sleepSegmentedControl.selectedSegmentIndex]];
}

-(IBAction)healthValueChanged:(id)sender {
    NSArray *HEALTH_VALUES = [[NSArray alloc] initWithObjects:@"1", @"2", @"3", @"4", @"5", nil];
    _health = [NSString stringWithFormat:[@"%@", HEALTH_VALUES objectAtIndex:healthSegmentedControl.selectedSegmentIndex]];
}

-(BOOL)postSignUpData {
    if (genderSegmentedControl == NULL || sleepSegmentedControl == NULL || activityLevelSegmentedControl == NULL || healthSegmentedControl == NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Field Empty!" message:@"You must complete all fields!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        NSLog(@"Field empty!");
        return FALSE;
    }
    
    else {
        NSString *post = [NSString stringWithFormat:@"sex=%@&activity=%@&sleep=%@&health=%@&age=%i&height=%i&weight=%i", _gender, _activity, _sleep, _health, age, height, weight];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/signup", ROOT_ADDRESS]];
        NSError *error;
        NSData *data = [self sendPostRequest:post forURL:url];
        
        NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"String From Data: %@", stringFromData);
        
        NSDictionary *signupResponseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        self.deviceID = [NSString stringWithFormat:@"%@", [signupResponseDictionary valueForKey:@"id"]];
        NSLog(@"Signup Response Device ID: %@", self.deviceID);
        
        NSLog(@"Device ID (From Database): %@", self.deviceID);
        [SSKeychain setPassword:self.deviceID forService:@"DeviceDetails" account:@"deviceID"];
        //        [SSKeychain setPassword:@"1" forService:@"DeviceDetails" account:@"deviceID"];  //Tester Code
        
        return TRUE;
    }
}

-(BOOL)postHealthData:(int)dataValue forDataType:(NSString *)dataType withUnits:(NSString *)dataUnits {
    
    NSDate *now = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSArray *keychainArray = [SSKeychain accountsForService:KEYCHAIN_SERVICE_POST];
    if ([keychainArray count] > 0 && [self validateAuthorization]) {
        NSString *acct = [keychainArray[0] objectForKey:dataType];
        self.lastPosted = [SSKeychain passwordForService:KEYCHAIN_SERVICE_POST account:acct];
        NSLog(@"Last Posted (From Keychain) %@", self.deviceID);
        
        NSDate *lastPost = [dateFormatter dateFromString:self.lastPosted];
        if ([self daysBetween:lastPost and:now] <= 24) {
            return FALSE;
        }
    }
    
    NSString *post = [NSString stringWithFormat:@"user_id=%@&data_type=%@&value=%i&unit=%@", self.deviceID, dataType, dataValue, dataUnits];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/update", ROOT_ADDRESS]];
    NSError *error;
    NSData *data = [self sendPostRequest:post forURL:url];
    
    NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"String From Data Update: %@", stringFromData);
    
    NSString *dateString = [dateFormatter stringFromDate:now];
    [SSKeychain setPassword:dateString forService:KEYCHAIN_SERVICE_POST account:dataType];
    self.lastPosted = dateString;
    
    return TRUE;
}


- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return [components hour]+1;
}

-(BOOL)isInternetConnection {
    //   Check for Internet Connection
    NSString *connect = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.apple.com"]] encoding:NSUTF8StringEncoding error:nil];
    //    NSLog(@"%@", connect);
    if (connect == NULL) {
        //No Internet Connection
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet!" message:@"You don't have an active internet connection. Please connect to the internet and try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return FALSE;
    }
    else {
        return TRUE;
    }
    
}

-(NSData *)sendPostRequest:post forURL:url {
    if (![self isInternetConnection]) {
        //No Internet Connection
        NSData *data = [[NSData alloc] init];
        return data;
    }
    else {
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        [request setURL:url]; //URL Here
        
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        [request setHTTPBody:postData];
        
        // Setting a timeout
        [request setTimeoutInterval: 20.0];
        
        //        NSURLConnection *conn = [[NSURLConnection alloc]initWithRequest:request delegate:self];
        //
        //        NSLog(@"%@", post);
        //
        //        if(conn) {
        //            NSLog(@"Connection Successful – Sign Up");
        //
        //        } else {
        //            NSLog(@"Connection could not be made – Sign Up");
        //        }
        
        // Fetch the JSON response
        NSData *urlData;
        NSURLResponse *response;
        NSError *error;
        
        // Make synchronous request
        urlData = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:&response
                                                    error:&error];
        
        // Construct a String around the Data from the response
        
        return urlData;
    }
}

-(IBAction)showAdditionalInfo:(id)sender {
    POPBasicAnimation *fadeIn = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    fadeIn.property = [POPAnimatableProperty propertyWithName:kPOPViewAlpha];
    fadeIn.toValue = @(1.0);
    fadeIn.duration = 0.3;
    [additionalInfoView pop_addAnimation:fadeIn forKey:@"fadeIn"];
}

-(IBAction)showBasicInfo:(id)sender {
    POPBasicAnimation *fadeOut = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    fadeOut.property = [POPAnimatableProperty propertyWithName:kPOPViewAlpha];
    fadeOut.toValue = @(0.0);
    fadeOut.duration = 0.3;
    [additionalInfoView pop_addAnimation:fadeOut forKey:@"fadeOut"];
}

-(IBAction)submitInfo:(id)sender {
    if ([self postSignUpData]) {
        [self performSegueWithIdentifier:@"InitialToMain" sender:self];
    }
}

//Table View Methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)myTableView {
    return 1;
}

//No of rows in the Table View
-(NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    return [healthData count];
}


-(CGFloat)tableView:(UITableView *)myTableView heightForHeaderInSection:(NSInteger)section {
    return 0; //Cell Spacing
}

-(UIView *)tableView:(UITableView *)myTableView viewForHeaderInSection:(NSInteger)section {
    UIView *v = [UIView new];
    [v setBackgroundColor:[UIColor clearColor]];
    return v;
}


-(UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    CustomCell *cell;
    
    if (cell == nil) {
        cell = [[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //    NSLog(@"%@", healthData);
    if ([healthData count] > 0) {
        //        NSLog(@"HealthData array at load time: %@", healthData);
        if ([[healthData objectAtIndex:indexPath.row] count] >= 2) {
            NSString *userDataValue = [[healthData objectAtIndex:indexPath.row] objectAtIndex:1];
            NSString *userDataType = [NSString stringWithFormat:@"%@", [[healthData objectAtIndex:indexPath.row] objectAtIndex:0]];
            NSString *userDataTypePrint = [userDataType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            NSString *userDataUnit = [[healthData objectAtIndex:indexPath.row] objectAtIndex:2];
            [cell.userDataValue setText:userDataValue];
            [cell.userDataType setText:userDataUnit];
            [cell.healthDataIcon setImage:[UIImage imageNamed:[imageDictionary valueForKey:userDataType]]];
            [self getAverage:userDataType];
            int mean = [self getMean:userDataType];
            mean = mean/CONSTANT_VALUE;
            NSString *meanText = [NSString stringWithFormat:@"%i", mean];
            if (mean < 0) {
                meanText = @"N/A";
            }
            NSString *CUDataValueText = [NSString stringWithFormat:@"%@", meanText];
            [cell.CUDataValue setText:CUDataValueText];
        }
    }
    
    UIView *selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    cell.selectedBackgroundView = selectionColor;
    
    return cell;
    
}

-(NSArray *)tableView:(UITableView *)myTableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *leaveButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Set Reminder" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                         {
                                             [self setReminder:indexPath];
                                         }];
    [leaveButton setBackgroundColor:[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0]];
    return @[leaveButton];
}

- (void)tableView:(UITableView *)myTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // you need to implement this method too or nothing will work:
    
}
- (BOOL)tableView:(UITableView *)myTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)myTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Selected row
    [myTableView deselectRowAtIndexPath:indexPath animated:YES];
    selectedDataType = [[[healthData objectAtIndex:indexPath.row] objectAtIndex:0] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    selectedDataValue = [[healthData objectAtIndex:indexPath.row] objectAtIndex:1];
    selectedDataUnit = [[healthData objectAtIndex:indexPath.row] objectAtIndex:2];
    
    NSLog(@"selectedDataType: %@", selectedDataType);
    [self viewDetails:indexPath];
}

-(void)viewDetails:(NSIndexPath *)indexPath {
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    anim.toValue = @(self.view.frame.size.height/2);
    anim.springBounciness = 10;
    anim.springSpeed = 1.2;
    anim.dynamicsFriction = 10.0;
    [detailView pop_addAnimation:anim forKey:@"slide"];
    
    //Assign DetailView values
    NSString *selectedDataTypePrint = [selectedDataType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    [detailDataIcon setImage:[UIImage imageNamed:[imageDictionary objectForKey:selectedDataType]]];
    NSString *selectedDataValue1 = [NSString stringWithFormat:@"%.0f", [selectedDataValue floatValue]];
//    [detailUserDataValue setText:[NSString stringWithFormat:@"%@", selectedDataValue1]];
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSString *dateString = [formatter stringFromDate:date];
    
    int mean = [self getMean:selectedDataType]/CONSTANT_VALUE;
    int difference = [selectedDataValue1 intValue] - mean;
    
    NSString *moreLess;
    if ([selectedDataValue1 intValue] > mean) {
        moreLess = @"more";
        [detailDayValue setTextColor:[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0]];
    }
    else {
        moreLess = @"less";
        difference = difference * -1;
        [detailDayValue setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];
    }

    
    NSString *meanText;
    if (mean < 0) {
        meanText = @"N/A";
        difference = difference + mean;
    }
    else {
        meanText = [NSString stringWithFormat:@"%i", mean];
    }
    NSString *diffText = [NSString stringWithFormat:@"%i", difference];
    
    detailDataType.text = [NSString stringWithFormat:@"%@", selectedDataUnit];
    [detailUserDataValue setText:[NSString stringWithFormat:@"%@", selectedDataValue1]];
    detailDayValue.text = [NSString stringWithFormat:@"%@ %@", diffText, moreLess];
    
    [detailDateText setText:[NSString stringWithFormat:@"on %@", dateString]];
    [detailCUDataValue setText:[NSString stringWithFormat:meanText]];
    
    [self displayBarChart];
}

-(IBAction)backToMainView:(id)sender {
    POPBasicAnimation *slideOut = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
    slideOut.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionY];
    slideOut.toValue = @(3*self.view.frame.size.height/2);
    slideOut.duration = 0.3;
    [detailView pop_addAnimation:slideOut forKey:@"slideOutDetail"];
    
}

-(void)addDataToArray:(NSString *)dataValue forDataType:(NSString *)dataType withUnits:(NSString *)dataUnits {
    NSArray *fullDataArray = [NSArray arrayWithObjects:dataType, dataValue, dataUnits, nil];
    [healthData addObject:fullDataArray];
    NSLog(@"Added %@ to healthData", fullDataArray);
    [self postHealthData:[dataValue intValue] forDataType:dataType withUnits:dataUnits];
    [self reloadTable];
}

-(void)postAllHealthData {
    NSLog(@"PostAll Health Data Running. HealthData has %ld values", [healthData count]);
    for (int i=0; i<[healthData count]; i++) {
        NSArray *dataArray = [healthData objectAtIndex:i];
        NSLog(@"Posting %@", dataArray);
        [self postHealthData:[[dataArray objectAtIndex:1] intValue] forDataType:[dataArray objectAtIndex:0] withUnits:[dataArray objectAtIndex:2]];
    }
}

-(void)reloadTable {
    [tableView reloadData];
    NSLog(@"%@", healthData);
    if ([tableView numberOfRowsInSection:0] > 0) {
        [spinner stopAnimating];
        [loading setHidden:YES];
        [loadingView setHidden:YES];
    }
    
    NSLog(@"%ld items in array", [healthData count]);
    if ([healthData count] == 0) {
        UIAlertView *noDataAlert = [[UIAlertView alloc] initWithTitle:@"No Data!" message:@"It appears your device is not collecting any data" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        //        [noDataAlert show];
    }
}

-(void)getAverage:(NSString *)dataType {
    NSString *post = [NSString stringWithFormat:@"data_type=%@", dataType];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/community_mean", ROOT_ADDRESS]];
    NSData *data = [self sendPostRequest:post forURL:url];
    
    NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Community Mean String From Data: %@", stringFromData);
    
    //    NSDictionary *communityMeanResponseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
}

-(void)displayBarChart {
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.dataSource = self;
    self.barChartView.delegate = self;
    self.barChartView.frame = CGRectMake(10, 220, 300, 200);
    //    self.barChartView.backgroundColor = [UIColor clearColor];
    [detailView addSubview:self.barChartView];
    [self.barChartView reloadData];
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    [self.barChartView setMinimumValue:0.0];
    
    CGRect barFrame = self.barChartView.frame;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(barFrame.origin.x, barFrame.origin.y + barFrame.size.height + 50.0, barFrame.size.width, 50)];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    
    NSDate *chartEndDate = [[NSDate alloc] init];
    NSString *chartEndDateString = [formatter stringFromDate:chartEndDate];
    
    int daysToAdd = -4;
    
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daysToAdd];
    
    // create a calendar
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDate *chartStartDate = [gregorian dateByAddingComponents:components toDate:chartEndDate options:0];
    NSString *chartStartDateString = [formatter stringFromDate:chartStartDate];


    UILabel *startDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 80, 20)];
    [startDateLabel setText:[NSString stringWithFormat:chartStartDateString]];
    [startDateLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:14]];
    [startDateLabel setTextAlignment:NSTextAlignmentLeft];
    [startDateLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
    
    UILabel *redBarKey = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 80, 20)];
    [redBarKey setText:[NSString stringWithFormat:@"You"]];
    [redBarKey setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14]];
    [redBarKey setTextAlignment:NSTextAlignmentLeft];
    [redBarKey setTextColor:[UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:1.0]];
    
    
    UILabel *endDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, 10, 80, 20)];
    [endDateLabel setText:[NSString stringWithFormat:chartEndDateString]];
    [endDateLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:14]];
    [endDateLabel setTextAlignment:NSTextAlignmentRight];
    [endDateLabel setTextColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
    
    UILabel *blueBarKey = [[UILabel alloc] initWithFrame:CGRectMake(210, 30, 80, 20)];
    [blueBarKey setText:[NSString stringWithFormat:@"CU"]];
    [blueBarKey setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14]];
    [blueBarKey setTextAlignment:NSTextAlignmentRight];
    [blueBarKey setTextColor:[UIColor colorWithRed:0.1 green:0.8 blue:0.9 alpha:1.0]];
    
    [footer addSubview:redBarKey];
    [footer addSubview:blueBarKey];
    [footer addSubview:startDateLabel];
    [footer addSubview:endDateLabel];
    [footer setBackgroundColor:[UIColor colorWithRed:0.0 green:0.1 blue:0.3 alpha:0.0]];
    [footer setAlpha:1.0];
    [[footer layer] setCornerRadius:3.0];
    [self.view addSubview:footer];
    
    [self.barChartView setFooterView:footer];
}

- (void)dealloc
{
    self.barChartView.delegate = nil;
    self.barChartView.dataSource = nil;
}

- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    return [pastUserValues count]; // number of bars in chart
}

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    if (index%2 == 0) {
        return [[pastUserValues objectAtIndex:index] floatValue] + 10.0; // height of bar at index
    }
    else {
        return [[pastCUValues objectAtIndex:index] floatValue] + 10.0; // height of bar at index
    }
    
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index {
    NSArray *barColors = [NSArray arrayWithObjects:[UIColor colorWithRed:0.1 green:0.8 blue:0.9 alpha:1.0], [UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:1.0], nil];
    return barColors[(index+1)%2];
}

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor purpleColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return 3.0;
}

//Bar Selected
- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    //    //Assign DetailView values
    //    NSString *selectedDataTypePrint = [selectedDataType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    //    [detailDataType setText:selectedDataUnit];
    //    [detailDataIcon setImage:[UIImage imageNamed:[imageDictionary objectForKey:selectedDataType]]];
    //    NSString *selectedDataValue1 = [NSString stringWithFormat:@"%.0f", [selectedDataValue floatValue]];
    //    detailDayValue.text = [NSString stringWithFormat:@"%@ %@", selectedDataValue1, selectedDataUnit];
    //
    //    NSDate *date = [[NSDate alloc] init];   //Get Date from Database
    //    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //    [formatter setDateFormat:@"MM/dd/yyyy"];
    //    NSString *dateString = [formatter stringFromDate:date];
    //
    //    [detailDateText setText:[NSString stringWithFormat:@"on %@", dateString]];
    
}

//Bar Released
- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    
}


-(void)getPastHealthData:(NSString *)forDataType identifier:(NSString *)userID {
    //Past one week's data for user and community, for the given data type
    
    
}

-(int)getMean:(NSString *)dataType {
    NSString *post = [NSString stringWithFormat:@"data_type=%@", dataType];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/community_mean", ROOT_ADDRESS]];
    NSError *error;
    NSData *data = [self sendPostRequest:post forURL:url];
    
    NSString *stringFromData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *communityMeanResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    int mean = [communityMeanResponse valueForKey:@"mean"];
    
    return mean;
}

-(void)setReminder:(NSIndexPath *)indexPath {
    
    NSLog(@"Setting Reminder");
    
    CustomCell *cell;
    cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSDate *notificationDate = [[NSDate date] dateByAddingTimeInterval:7200]; //Two Hours Later
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    [notification setAlertBody:[NSString stringWithFormat:@"You need to improve your %@.", cell.userDataType.text]];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    NSString *alertMessage = [NSString stringWithFormat:@"You will be reminded to improve your %@ in 2 hours", cell.userDataType.text];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reminder Set" message:alertMessage delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

-(IBAction)showSideView:(id)sender {
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    anim.toValue = @(self.view.frame.size.width/2);
    anim.springBounciness = 3;
    anim.springSpeed = 1.0;
    anim.dynamicsFriction = 24.0;
    [sideView pop_addAnimation:anim forKey:@"slideInSide"];
}


-(IBAction)showInfo:(id)sender {
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    anim.toValue = @(self.view.frame.size.height/2);
    anim.springBounciness = 10;
    anim.springSpeed = 1.2;
    anim.dynamicsFriction = 14.0;
    [infoView pop_addAnimation:anim forKey:@"slideInInfo"];
}

- (IBAction)hideSideView:(id)sender {
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    anim.toValue = @(- (self.view.frame.size.height*2));
    anim.springBounciness = 10;
    anim.springSpeed = 1.2;
    anim.dynamicsFriction = 14.0;
    [sideView pop_addAnimation:anim forKey:@"slideOutSide"];
}

- (IBAction)hideInfoView:(id)sender {
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    anim.toValue = @(2*self.view.frame.size.height);
    anim.springBounciness = 10;
    anim.springSpeed = 1.2;
    anim.dynamicsFriction = 14.0;
    [infoView pop_addAnimation:anim forKey:@"slideOutInfo"];
}

@end
