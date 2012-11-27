//
//  MainViewController.m
//  Echo
//
//  Created by Will Entriken on 11/26/12.
//
//

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {SectionLessons, SectionPractice, SectionPeople, SectionCount} Sections;

@interface MainViewController ()

@end

@implementation MainViewController

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
    [tempImageView setFrame:self.tableView.frame];
    self.tableView.backgroundView = tempImageView;


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SectionLessons)
        return @"Lessons";
    else if (section == SectionPractice)
        return @"Practice";
    else if (section == SectionPeople)
        return @"People";
    else
        return nil;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Create label with section title
    UILabel *label = [[UILabel alloc] init] ;
    label.frame = CGRectMake(100, 5, 140, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
//    label.shadowColor = [UIColor whiteColor];
//    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:20];
    label.text = [self tableView:tableView titleForHeaderInSection:section];

    UIImage *icon;
    if (section == SectionLessons)
        icon = [UIImage imageNamed:@"echo"];
    else if (section == SectionPractice)
        icon = [UIImage imageNamed:@"practiceIcon"];
    else if (section == SectionPeople)
        icon = [UIImage imageNamed:@"social"];

    UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    iconView.frame = CGRectMake(65, 5, 30, 30);
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(50, 5, 200, 30)];
  
    if (section == SectionLessons)
        background.backgroundColor = [UIColor colorWithRed:61.0/256 green:100.0/256 blue:212.0/256 alpha:1.0];
    else if (section == SectionPractice)
        background.backgroundColor = [UIColor colorWithRed:29.0/256 green:140.0/256 blue:38.0/256 alpha:1.0];
    else if (section == SectionPeople)
        background.backgroundColor = [UIColor colorWithRed:140.0/256 green:38.0/256 blue:29.0/256 alpha:1.0];

    background.layer.cornerRadius = 5;
    background.layer.masksToBounds = NO;
    [background.layer setCornerRadius:10.0f];
    [background.layer setBorderColor:[UIColor blackColor].CGColor];
    [background.layer setBorderWidth:1.5f];
    [background.layer setShadowColor:[UIColor blackColor].CGColor];
    [background.layer setShadowOpacity:0.8];
    [background.layer setShadowRadius:3.0];
    [background.layer setShadowOffset:CGSizeMake(2.0, 2.0)];

    
    [view addSubview:background];
    [view addSubview:label];
    [view addSubview:iconView];

    
    return view;
    /*
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 100, 200)];
    view.backgroundColor = [UIColor redColor];
    UIImage *icon = [UIImage imageNamed:@"echo"];
    UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    [view addSubview:iconView];
    return view;
     */
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SectionLessons)
        return 4;
    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"lesson";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
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

@end
