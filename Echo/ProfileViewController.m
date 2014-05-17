//
//  ProfileViewController.m
//  Echo
//
//  Created by Will Entriken on 3/16/13.
//
//

#import "ProfileViewController.h"
#import "Profile.h"
#import "Languages.h"
#import "LanguageSelectController.h"
#import "FDTakeController.h"
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"
#import "NetworkManager.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "FDRightDetailWithTextFieldCell.h"

@interface ProfileViewController () <LanguageSelectControllerDelegate, FDTakeDelegate, CLLocationManagerDelegate, MBProgressHUDDelegate>
@property (strong, nonatomic) UILabel *labelSelectingLanguage;
@property (strong, nonatomic) FDTakeController *takeController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation ProfileViewController

- (CLLocationManager *)locationManager
{
    if (!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;

    FDRightDetailWithTextFieldCell *cell = (FDRightDetailWithTextFieldCell *)[self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    self.name = cell.textField;
    
    Profile *me = [Profile currentUserProfile];
    self.name.text = me.username;
    self.learningLang.text = [Languages nativeDescriptionForLanguage:me.learningLanguageTag];
    self.nativeLang.text = [Languages nativeDescriptionForLanguage:me.nativeLanguageTag];
    self.learningLangTag = me.learningLanguageTag;
    self.nativeLangTag = me.nativeLanguageTag;
    self.location.text = me.location;
    self.photo.image = me.photo;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"ProfileView"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Full profile is shared online";
    return nil;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        if ([self.learningLang isDescendantOfView:sender]) {
            self.labelSelectingLanguage = self.learningLang;
            LanguageSelectController *controller = segue.destinationViewController;
            controller.navigationItem.title = @"Learning language";
        }
        else {
            self.labelSelectingLanguage = self.nativeLang;
            LanguageSelectController *controller = segue.destinationViewController;
            controller.navigationItem.title = @"Native language";
        }
        controller.delegate = self;
    }
}

#pragma mark - ScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES]; // fucking nice
}

- (IBAction)checkIn:(id)sender {
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    //self.hud.labelText = @"Getting location...";
    [self.locationManager startUpdatingLocation];
}

- (IBAction)choosePhoto:(id)sender {
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.popOverPresentRect = [(UIButton *)sender frame];
    self.takeController.imagePicker.allowsEditing = YES;
    self.takeController.delegate = self;
    [self.takeController takePhotoOrChooseFromLibrary];
}

- (IBAction)save:(id)sender {
    Profile *me = [Profile currentUserProfile];
    me.username = self.name.text;
    me.learningLanguageTag = self.learningLangTag;
    me.nativeLanguageTag = self.nativeLangTag;
    me.photo = self.photo.image;
    me.location = self.location.text;
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Sending...";
    
    [me syncOnlineOnSuccess:^(NSArray *recommendedLessons)
     {
         for (Lesson *lesson in recommendedLessons) 
             [self.delegate downloadLessonViewController:self gotStubLesson:lesson];
         [self.hud hide:YES];
         [me syncToDisk];
         [self.navigationController popViewControllerAnimated:YES];
     } onFailure:^(NSError *error) {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
     }];
}

- (IBAction)labelIsCallingLanguageSelect:(UILabel *)sender
{
    self.labelSelectingLanguage = sender;
}

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    if (self.labelSelectingLanguage == self.learningLang) {
        self.learningLang.text = name;
        self.learningLangTag = tag;
    } else {
        self.nativeLang.text = name;
        self.nativeLangTag = tag;
    }
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - FDTakeController

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    self.photo.image = photo;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations objectAtIndex:0];
    [manager stopUpdatingLocation];
    self.location.text = [NSString stringWithFormat:@"%+3.2f, %+3.2f", location.coordinate.latitude, location.coordinate.longitude];
    [self.hud hide:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self.hud hide:NO];
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.delegate = self;
    UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view.text = error.localizedDescription;
    view.font = self.hud.labelFont;
    view.textColor = [UIColor whiteColor];
    view.backgroundColor = [UIColor clearColor];
    [view sizeToFit];
    self.hud.customView = view;
    self.hud.mode = MBProgressHUDModeCustomView;
    [self.hud hide:YES afterDelay:2];
    NSLog(@"GOT LOCATION ERROR %@", error.localizedDescription);
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqual:@"photo"])
        [self choosePhoto:nil];
    else if ([cell.reuseIdentifier isEqual:@"location"])
        [self checkIn:nil];
}

@end
