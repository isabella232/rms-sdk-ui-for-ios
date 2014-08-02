/*
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *
 * FileName:     MSEmailInputViewController.m
 *
 */

#import <UIKit/UIKit.h>

#import "MSEmailInputViewController.h"
#import "ResourcesUtils.h"

@interface MSEmailInputViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *rmsLogo;
@property (weak, nonatomic) IBOutlet UILabel *emailAddressRequestLabel;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIActivityIndicatorView *progressIndicator;
@property (nonatomic) BOOL waitingFlag; // to record the state that we are waiting on the sdk

- (IBAction)onContinueTapped:(id)sender;
- (IBAction)onCancelTapped:(id)sender;
- (IBAction)onPrivacyTapped:(id)sender;
- (IBAction)onHelpTapped:(id)sender;

@end

@implementation MSEmailInputViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // Intentionally left empty
    }

    return self;
}

#pragma mark - local helper methods

///Returns YES (true) if Email is valid
+(BOOL) IsValidEmail:(NSString *)emailString Strict:(BOOL)strictFilter
{
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    
    NSString *emailRegex = strictFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:emailString];
}

#pragma mark - Private methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = self.waitingFlag;
    self.navigationItem.hidesBackButton = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI actions
- (IBAction)onContinueTapped:(id)sender
{
    NSLog(@"Continue tapped.. current email address is %@", self.emailTextField.text);
    [self.view endEditing:YES];
    
    // perform some basic RegEx checks to validate the email address string
    if ([MSEmailInputViewController IsValidEmail:self.emailTextField.text Strict:YES] != YES)
    {
        NSLog(@"Invalid email address..");
        
        if (self.errorLabel == nil)
        {
            // Place the error label appropriately
            CGFloat errorLabelYOffset = 170.0f;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                NSLog(@"iPad offset for error label");
                errorLabelYOffset = 160.0f;
            }
            
            self.errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.emailTextField.frame.origin.x,
                                                                        self.emailTextField.frame.origin.y - errorLabelYOffset,
                                                                        200, 200)];
            self.errorLabel.text = LocalizeString(@"ERROR_INVALID_EMAIL_ADDRESS_STRING", @"Invalid email address.");
            [self.errorLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:12]];
            self.errorLabel.textColor = [UIColor redColor];
            self.errorLabel.tag = 9999; // Need this tag to identify and remove the label later
            [self.view addSubview:self.errorLabel];
        }
    }
    else
    {
        NSLog(@"Valid email address entered..");
        
        // Initialize the progress indicator
        if (self.progressIndicator == nil)
        {
            self.progressIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.progressIndicator.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
            self.progressIndicator.center = self.view.center;
            [self.view addSubview:self.progressIndicator];
            [self.progressIndicator bringSubviewToFront:self.view];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
        }
        
        // Remove the "invalid email address" message if it was displayed
        for (UIView *subView in self.view.subviews)
        {
            if (subView.tag == 9999)
            {
                [subView removeFromSuperview];
            }
        }
        
        // Disable the interactive UI
        self.waitingFlag = YES;
        [self hideOrShowAllViewsOnScreen:YES];
        [self.progressIndicator startAnimating];
        
        [self.delegate onEmailInputTappedWithEmail:self.emailTextField.text completionBlock:^(BOOL completed){
             
            self.waitingFlag = NO;

            // Restore UI look and function
            [self.progressIndicator stopAnimating];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;

            if (completed == NO)
            {
                 NSLog(@"Auth failed..");
                 [self hideOrShowAllViewsOnScreen:NO];
            }
        }];
    }
}

- (IBAction)onCancelTapped:(id)sender
{
    NSLog(@"Cancel tapped..");
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPrivacyTapped:(id)sender
{
    NSLog(@"Privacy tapped..");
    // open the link in Safari app and moves our app to the background
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://go.microsoft.com/fwlink/?LinkId=317563"]];
}

- (IBAction)onHelpTapped:(id)sender
{
    NSLog(@"Help tapped..");
    // open the link in Safari app and moves our app to the background
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://go.microsoft.com/fwlink/?LinkId=317564"]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Screen touched");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"Enter hit..");
    [self.view endEditing:YES];
    [self onContinueTapped:self];
    
    return YES;
}

#pragma mark - Helper methods

// method to hide or show all elements on screen based on input parameter
-(void)hideOrShowAllViewsOnScreen:(BOOL)hide
{
    self.navigationController.navigationBarHidden = hide;
    [self.rmsLogo setHidden:hide];
    [self.emailAddressRequestLabel setHidden:hide];
    [self.emailTextField setHidden:hide];
    [self.continueButton setHidden:hide];
    [self.privacyButton setHidden:hide];
    [self.helpButton setHidden:hide];
}

@end


