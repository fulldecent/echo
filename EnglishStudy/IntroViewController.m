//
//  IntroViewController.m
//  Echo
//
//  Created by Will Entriken on 11/24/12.
//
//

#import "IntroViewController.h"

@interface IntroViewController () <UITextFieldDelegate>

@end

@implementation IntroViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nameField.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setNameField:nil];
    [self setLanguageButtons:nil];
    [super viewDidUnload];
}
- (IBAction)nameChanged:(UITextField *)sender {
    NSLog(@"%@", sender.text);
    for (UIButton *button in self.languageButtons)
        button.enabled = sender.text.length > 0;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
