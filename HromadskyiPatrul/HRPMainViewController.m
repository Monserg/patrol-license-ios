//
//  HRPViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPMainViewController.h"
#import "HRPCollectionViewController.h"
#import "HRPVideoRecordViewController.h"
#import "HRPButton.h"
#import "UIColor+HexColor.h"
#import <NSString+Email.h>
#import "HRPMainViewModel.h"


@interface HRPMainViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel1;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel2;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel3;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet HRPButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *madeByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *stfalconLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@end

@implementation HRPMainViewController {
    HRPMainViewModel *_mainViewModel;

    CGSize keyboardSize;
    NSInteger countt;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    // Create model
    _mainViewModel                              =   [[HRPMainViewModel alloc] init];
    
    countt                                      =   0;
    
    // Set Scroll View constraints
    self.contentViewWidthConstraint.constant    =   CGRectGetWidth(self.view.frame);
    self.contentViewHeightConstraint.constant   =   CGRectGetHeight(self.view.frame);
    
    // Set Status Bar
    UIView *statusBarView                       =  [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor               =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.view addSubview:statusBarView];
    
    self.versionLabel.text                      =   [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"Version", nil),
                                                        [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                        [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
    
    // Set Logo text
    self.logoLabel.text                         =   NSLocalizedString(@"Public patrol", nil);
    self.aboutLabel1.text                       =   NSLocalizedString(@"About text 1", nil);
    self.aboutLabel2.text                       =   NSLocalizedString(@"About text 2", nil);
    self.aboutLabel3.text                       =   NSLocalizedString(@"About text 3", nil);
    
    // Set button title
    [self.loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self showLoaderWithText:NSLocalizedString(@"Launch text", nil) andBackgroundColor:BackgroundColorTypeBlack];

    if ([_mainViewModel.userApp objectForKey:@"userAppEmail"]) {
        self.emailTextField.text                =   [_mainViewModel.userApp objectForKey:@"userAppEmail"];
       
        if (countt == 0) {
            countt++;
            
            [self startSceneTransition];
        }
    }
    
    else {
        [UIView animateWithDuration:1.3f
                         animations:^{
                             self.versionLabel.alpha                                =   0.f;
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.7f
                                              animations:^{
                                                  self.stfalconLogoImageView.alpha  =   1.f;
                                                  self.madeByLabel.alpha            =   1.f;
                                              }
                                              completion:^(BOOL finished) {
                                                  [self hideLoader];
                                              }];
                         }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexString:@"0477BD" alpha:1.f]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}


#pragma mark - Actions -
- (IBAction)actionLoginButtonTap:(HRPButton *)sender {
    // Email validation
    if ([self.emailTextField.text isEmail]) {
        // API
        if ([self isInternetConnectionAvailable]) {
            [_mainViewModel userLoginParameters:self.emailTextField.text
                            onSuccess:^(NSDictionary *successResult) {
                                [self. emailTextField resignFirstResponder];

                                // Transition to VideoRecord scene
                                [self startSceneTransition];
                                
                                // Set NSUserDefaults item
                                [_mainViewModel.userApp setObject:self.emailTextField.text forKey:@"userAppEmail"];
                                [_mainViewModel.userApp setObject:successResult[@"id"] forKey:@"userAppID"];
                                [_mainViewModel.userApp synchronize];
                            }
                            orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                                  andMessage:NSLocalizedString(@"Alert error API message", nil)];
                            }];
        }
    }
    
    // Email error
    else
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert error email title", nil)
                          andMessage:NSLocalizedString(@"Alert error email message", nil)];
}


#pragma mark - NSNotification -
- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info                          =   [notification userInfo];
    keyboardSize                                =   [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGFloat emailPositionY                      =   CGRectGetMaxY(self.emailTextField.frame);
    CGFloat keyboardPositionTop                 =   self.contentViewHeightConstraint.constant - keyboardSize.height - 10.f;
    
    if (emailPositionY > keyboardPositionTop)
        [self.scrollView setContentOffset:CGPointMake(0.f, emailPositionY - keyboardPositionTop) animated:YES];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


#pragma mark - UIGestureRecognizer -
- (IBAction)handleGestureRecognizerTap:(UITapGestureRecognizer *)sender {
    [self. emailTextField resignFirstResponder];
}


#pragma mark - Methods -
- (void)startSceneTransition {
    // Transition to VideoRecord scene
    UINavigationController *videoRecordNC       =   [self.storyboard instantiateViewControllerWithIdentifier:@"VideoRecordNC"];
    
    [self presentViewController:videoRecordNC animated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self actionLoginButtonTap:self.loginButton];
    
    return  YES;
}

@end
