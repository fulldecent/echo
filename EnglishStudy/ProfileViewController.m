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

@interface ProfileViewController () <LanguageSelectControllerDelegate, FDTakeDelegate, CLLocationManagerDelegate, MBProgressHUDDelegate>
@property (strong, nonatomic) UILabel *labelSelectingLanguage;
@property (strong, nonatomic) FDTakeController *takeController;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation ProfileViewController
@synthesize name = _name;
@synthesize learningLang = _learningLang;
@synthesize nativeLang = _nativeLang;
@synthesize learningLangTag = _learningLangTag;
@synthesize nativeLangTag = _nativeLangTag;
@synthesize photo = _photo;
@synthesize location = _location;
@synthesize labelSelectingLanguage = _labelSelectingLanguage;
@synthesize takeController = _takeController;
@synthesize locationManager = _locationManager;
@synthesize hud = _hud;

- (CLLocationManager *)locationManager
{
    if (!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
    
    Profile *me = [Profile currentUserProfile];
    self.name.text = me.username;
    self.learningLang.text = [Languages nativeDescriptionForLanguage:me.learningLanguageTag];
    self.nativeLang.text = [Languages nativeDescriptionForLanguage:me.nativeLanguageTag];
    self.learningLangTag = me.learningLanguageTag;
    self.nativeLangTag = me.nativeLanguageTag;
    self.location.text = me.location;
    self.photo.image = me.photo;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        if ([self.learningLang isDescendantOfView:sender])
            self.labelSelectingLanguage = self.learningLang;
        else
            self.labelSelectingLanguage = self.nativeLang;
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
    
    [me syncOnlineOnSuccess:^
     {
         NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
         NSArray *recommendedLessons = networkManager.recommendedLessons;
         NSLog(@"%@", recommendedLessons);
         
         for (NSString *lessonJSON in recommendedLessons) {
#warning abstract me! / there is a copy/paste somewhere else too
             NSData *data = [lessonJSON dataUsingEncoding:NSUTF8StringEncoding];
             NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             
             Lesson *lesson = [[Lesson alloc] init];
             lesson.lessonID = [packed objectForKey:@"lessonID"];
             lesson.languageTag = [packed objectForKey:@"languageTag"];
             lesson.name = [packed objectForKey:@"name"];
             lesson.detail = [packed objectForKey:@"detail"];
             lesson.userID = [packed objectForKey:@"userID"];
             lesson.userName = [packed objectForKey:@"userName"];
             lesson.serverVersion = [packed objectForKey:@"updated"];
             if ([[packed objectForKey:@"lessonCode"] length])
                 lesson.lessonCode = [packed objectForKey:@"lessonCode"];
             else
                 lesson.lessonCode = [NSString string];
             
             [self.delegate downloadLessonViewController:self gotStubLesson:lesson];
         }
         
         [self.hud hide:YES];
         [me syncToDisk];
         [self.navigationController popViewControllerAnimated:YES];
     } onFailure:^(NSError *error)
     {
         [self.hud hide:YES];
         self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
         self.hud.delegate = self;
         self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
         UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
         view.text = error.localizedDescription;
         view.font = self.hud.labelFont;
         view.textColor = [UIColor whiteColor];
         view.backgroundColor = [UIColor clearColor];
         [view sizeToFit];
         self.hud.customView = view;
         self.hud.mode = MBProgressHUDModeCustomView;
         [self.hud hide:YES afterDelay:1.5];
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

@end
