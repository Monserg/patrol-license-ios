/*
 Copyright (c) 2015 - 2016. Stepan Tanasiychuk
 This file is part of Gromadskyi Patrul is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by the Free Software Found ation, version 3 of the License, or any later version.
 If you would like to use any part of this project for commercial purposes, please contact us
 for negotiating licensing terms and getting permission for commercial use. Our email address: info@stfalcon.com
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.
 If not, see http://www.gnu.org/licenses/.
 */
// https://github.com/stfalcon-studio/patrol-android/blob/master/app/build.gradle
//
//
//  HRPCollectionViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCollectionViewController.h"
#import "UIColor+HexColor.h"
#import "HRPButton.h"
#import "HRPViolationCell.h"
#import "HRPPhoto.h"
#import "HRPImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>
#import "HRPLocations.h"
#import <AFHTTPRequestOperation.h>
#import "HRPPhotoPreviewViewController.h"
#import "HRPVideoPlayerViewController.h"
#import "UIViewController+NavigationBar.h"
#import "HRPSettingsViewController.h"
#import "HRPCameraManager.h"
#import "HRPViolationManager.h"
#import "HRPViolation.h"
#import "HRPCameraController.h"
#import "HRPVideoRecordViewController.h"


typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface HRPCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) HRPViolationManager *violationManager;
@property (strong, nonatomic) HRPCameraController *imagePickerController;
@property (strong, nonatomic) IBOutlet UICollectionView *violationsCollectionView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userNameBarButton;

@end


@implementation HRPCollectionViewController {
    UIView *_statusView;
    BOOL _isCameraRun;
    UIDeviceOrientation _currentOrientation;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentOrientation = [[UIDevice currentDevice] orientation];
    
    // Create Manager & Violations data source
    _violationManager = [HRPViolationManager sharedManager];
    _isCameraRun = NO;
    
    if (self.isStartAsRecorder) {
        [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)
              andBackgroundColor:BackgroundColorTypeBlack
                         forTime:300];
    
        [_violationManager customizeManagerSuccess:^(BOOL isSuccess) {
            if (isSuccess)
                [_violationsCollectionView reloadData];
            
            [self hideLoader];
        }];
    }

    // Remove local file with violations array
    // Only for Debug mode
    //[_violationManager removeViolationsFromFile];
    
    _userNameBarButton.title = NSLocalizedString(@"Public patrol", nil);
    
    [self customizeNavigationBarWithTitle:nil
                     andLeftBarButtonText:_userNameBarButton.title
                        withActionEnabled:NO
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-settings-white"]
                        withActionEnabled:YES];
    
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerViolationSuccessUpload:)
                                                 name:@"violation_upload_success"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.isStartAsRecorder || _isCameraRun) {
        [_violationsCollectionView reloadData];
        
        if (_isCameraRun == 1)
            _isCameraRun = NO;
    }
    
    _violationManager.isCollectionShow = YES;
    [self setRightBarButtonEnable:YES];
    self.view.userInteractionEnabled = YES;
    CGSize size = [[UIScreen mainScreen] bounds].size;
    [_violationManager modifyCellSize:size];
    
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]) ||
        ([[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceUp && size.width < size.height)) {
        _statusView = [self customizeStatusBar];
        [[UINavigationBar appearance] addSubview:_statusView];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    
    [[HRPCameraManager sharedManager] stopVideoSession];
    [[HRPCameraManager sharedManager].videoPreviewLayer removeFromSuperlayer];
    
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    _violationManager.violations = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UICollectionViewFlowLayout *flowLayout = (id)_violationsCollectionView.collectionViewLayout;
    flowLayout.itemSize = _violationManager.cellSize;
    
    [flowLayout invalidateLayout]; //force the elements to get laid out again with the new size
}

- (BOOL)shouldAutorotate {
    return YES;
}


#pragma mark - Actions -
- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender {
    // E-mail button
}

- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Settings button
    [self setRightBarButtonEnable:NO];
    HRPSettingsViewController *settingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsTVC"];
    
    [_violationManager saveViolationsToFile:_violationManager.violations];

    // Handler change Auto upload item
    [settingsTVC setDidChangeAutoUploadItem:^(id item) {
        if ([item boolValue] == YES) {
            [_violationsCollectionView reloadData];
        }
    }];
    
    [self.navigationController pushViewController:settingsTVC animated:YES];
}

- (IBAction)handlerAlbumButtonTap:(UIButton *)sender {
    // Use device Album
    dispatch_async(dispatch_get_main_queue(), ^{
        HRPCameraController *libraryVC = [[HRPCameraController alloc] init];
        libraryVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        libraryVC.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
        libraryVC.allowsEditing = YES;
        libraryVC.delegate = self;
        
        libraryVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        _imagePickerController = libraryVC;

        [_violationManager saveViolationsToFile:_violationManager.violations];

        if (![_imagePickerController isBeingPresented])
            [self.navigationController presentViewController:_imagePickerController animated:YES completion:nil];
    });
}

- (IBAction)handlerRecordButtonTap:(UIButton *)sender {
    self.view.userInteractionEnabled = NO;
    _violationManager.isCollectionShow = NO;
    _isCameraRun = YES;
    
    [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:300];
    
    // Save current violations state to file
    _violationManager = [HRPViolationManager sharedManager];
    [_violationManager saveViolationsToFile:_violationManager.violations];
    
    // Create violations array
    [_violationManager customizeManagerSuccess:^(BOOL isSuccess) {
        if (!self.isStartAsRecorder) {
            [self.navigationController popViewControllerAnimated:YES];
            [(HRPVideoRecordViewController *)[self.navigationController.viewControllers lastObject] startVideoRecord];
            // NSLog(@"2. CollectionVC poped");
        }
        
        else {
            if (TARGET_IPHONE_SIMULATOR) {
                [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil) andMessage:NSLocalizedString(@"Camera is not available", nil)];
                
                [self hideLoader];
                self.view.userInteractionEnabled = YES;
            }
            
            else {
                HRPBaseViewController *nextVC = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoRecordVC"];
                
                [self.navigationController pushViewController:nextVC animated:YES];
                // NSLog(@"2. RecordVC pushed");
            }
        }
    }];
}

- (IBAction)handlerCameraButtonTap:(UIButton *)sender {
    // Use device camera
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([HRPCameraController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            HRPCameraController *cameraVC = [[HRPCameraController alloc] init];
            cameraVC.sourceType = UIImagePickerControllerSourceTypeCamera;
            cameraVC.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
            cameraVC.videoQuality = UIImagePickerControllerQualityTypeHigh;
            cameraVC.videoMaximumDuration = 60.0f; // 1 min
            cameraVC.allowsEditing = YES;
            cameraVC.delegate = self;
            
            cameraVC.modalPresentationStyle = UIModalPresentationFormSheet;
            _imagePickerController = cameraVC;
            
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

            if (![_imagePickerController isBeingPresented])
                [self.navigationController presentViewController:_imagePickerController
                                                        animated:YES
                                                      completion:^{
                                                          [cameraVC startUpdateLocations];
                                                      }];
        }
        
        else
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil) andMessage:NSLocalizedString(@"Camera is not available", nil)];
    });
}


#pragma mark - NSNotification -
- (void)handlerViolationSuccessUpload:(NSNotification *)notification {
    HRPViolation *violation = notification.userInfo[@"violation"];
    HRPViolation *violationNext = notification.userInfo[@"violationNext"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_violationManager.violations indexOfObject:violation]
                                                inSection:0];
    
    [_violationManager.violations replaceObjectAtIndex:indexPath.row withObject:violation];
    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:indexPath];
    cell.violation = violation;
    
    [cell customizeCellStyle];
    [cell uploadImage:indexPath inImages:_violationManager.images];
    [cell hideActivityLoader];
    
    // Upload next violation
    if (violationNext) {
        indexPath = [NSIndexPath indexPathForRow:[_violationManager.violations indexOfObject:violationNext]
                                       inSection:0];
        
        HRPViolationCell *cellNext = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:indexPath];
        [cellNext showActivityLoader];
        
        [_violationManager uploadViolation:violationNext
                                inAutoMode:YES
                                 onSuccess:^(BOOL isSuccess) {
                                     [cellNext hideActivityLoader];
                                 }];
    }
}


#pragma mark - Methods -
- (void)checkDeviceOrientation {
    if (_currentOrientation != [[UIDevice currentDevice] orientation]) {
        self.view.frame = CGRectMake(0.f, 0.f, UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) ? CGRectGetHeight(self.view.frame) : CGRectGetWidth(self.view.frame), UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) ? CGRectGetWidth(self.view.frame) : CGRectGetHeight(self.view.frame));
    }
}

- (void)removeViolationFromCollection:(NSIndexPath *)indexPath {
    [_violationsCollectionView performBatchUpdates:^{
        HRPViolation *violation = [_violationManager.violations objectAtIndex:indexPath.row];
        
        [_violationManager.violations removeObjectAtIndex:indexPath.row];
        [_violationManager.images removeObjectAtIndex:indexPath.row];
        [_violationsCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        
        // Remove files from Album
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAsset *assetViolationPhoto = [PHAsset fetchAssetsWithALAssetURLs:@[[NSURL URLWithString:violation.assetsPhotoURL]] options:nil].firstObject;
            PHAsset *assetViolationVideo = [PHAsset fetchAssetsWithALAssetURLs:@[[NSURL URLWithString:violation.assetsVideoURL]] options:nil].firstObject;
            
            [PHAssetChangeRequest deleteAssets:@[assetViolationPhoto, assetViolationVideo]];
        }
                                          completionHandler:nil];
    }
                                        completion:^(BOOL finished) {
                                            [_violationManager saveViolationsToFile:_violationManager.violations];
                                        }];
}

- (void)showAlertController:(NSIndexPath *)indexPath {
    HRPViolation *violation = _violationManager.violations[indexPath.row];
    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:indexPath];
    
    if (cell.activityLoader.hidden) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        /*
        UIAlertAction *actionOpenViolationPhoto = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Photo", nil)
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             HRPPhotoPreviewViewController *photoPreviewVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoPreviewVC"];
                                                                             
                                                                             photoPreviewVC.violation = violation;
                                                                             
                                                                             [self presentViewController:photoPreviewVC animated:YES completion:nil];
                                                                         }];
         */
        
        UIAlertAction *actionOpenViolationVideo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Video", nil)
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             HRPVideoPlayerViewController *videoPlayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoPlayerVC"];
                                                                             
                                                                             videoPlayerVC.videoURL = [NSURL URLWithString:violation.assetsVideoURL];
                                                                             _violationManager.isCollectionShow = NO;
                                                                             
                                                                             [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

                                                                             [self presentViewController:videoPlayerVC animated:YES completion:^{}];
                                                                         }];
        
        UIAlertAction *actionRemoveViolation = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Remove a Video" : @"Remove a Photo", nil)
                                                                        style:UIAlertActionStyleDestructive
                                                                      handler:^(UIAlertAction *action) {
                                                                          [self removeViolationFromCollection:indexPath];
                                                                      }];
        
        UIAlertAction *actionUploadViolation = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Upload a Video" : @"Upload a Photo", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          if (violation.state != HRPViolationStateDone) {
                                                                              // Check Video duration (<= 60 sec)
                                                                              AVURLAsset *videoFileAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:violation.assetsVideoURL] options:nil];
                                                                              CMTime duration = videoFileAsset.duration;
                                                                              
                                                                              if (CMTimeCompare(duration, CMTimeMake(62, 1)) == 1) {
                                                                                  [self showAlertViewWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                                                    andMessage:NSLocalizedString(@"Alert error video duration", nil)];
                                                                              } else {
                                                                                  [cell showActivityLoader];
                                                                                  [_violationManager uploadViolation:violation
                                                                                                          inAutoMode:NO
                                                                                                           onSuccess:^(BOOL isSuccess) {
                                                                                                               [cell hideActivityLoader];
                                                                                                           }];
                                                                              }
                                                                          }
                                                                      }];
        
        // ADD WHEN NEED
        /*
         UIAlertAction *actionUploadViolations = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Upload Videos" : @"Upload Photos", nil)
         style:UIAlertActionStyleDefault
         handler:^(UIAlertAction *action) {
         [_violationManager uploadViolations:_violationsCollectionView];
         }];
         
        
        if (violation.type == HRPViolationTypeVideo)
            [alertController addAction:actionOpenViolationVideo];
        else
            [alertController addAction:actionOpenViolationPhoto];
         */
        
        
        [alertController addAction:actionOpenViolationVideo];
        
        if (violation.state != HRPViolationStateDone && !violation.isUploading && _violationManager.uploadingCount < 2) {
            [alertController addAction:actionUploadViolation];
            [alertController addAction:actionRemoveViolation];
        }
        
        else
            [alertController addAction:actionRemoveViolation];
        
        // ADD WHEN NEED
        /*
         if (_violationManager.violationsNeedUpload.count > 0 && violation.type == HRPViolationTypePhoto)
         [alertController addAction:actionUploadViolations];
         */
        
        
        [alertController addAction:actionCancel];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - UICollectionViewDataSource -
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_violationManager.violations.count == 0)
        [self hideLoader];
    
    return _violationManager.violations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ViolationCell";
    HRPViolationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    HRPViolation *violation = _violationManager.violations[indexPath.row];
    
    if (_violationManager.uploadingCount == 0 && violation.isUploading) {
        violation.isUploading = NO;
        [_violationManager.violations replaceObjectAtIndex:indexPath.row withObject:violation];
    }
    
    cell.violation = violation;
    
    [cell customizeCellStyle];
    [cell uploadImage:indexPath inImages:_violationManager.images];
    
    
    // SET USERACTIVITY IN STORYBOARD - NOW IT DISABLED
    /*
     [cell.uploadStateButton setDidButtonPress:^(id item) {
     [_violationManager uploadViolation:item];
     }];
     */
    
    
    // ADD PAGINATION IF IT NEED
    /*
     // Set pagination
     if (indexPath.row == _violationsDataSource.count - 2) {
     isPaginationRun = YES;
     
     [self showLoaderWithText:NSLocalizedString(@"Upload title", nil)
     andBackgroundColor:BackgroundColorTypeBlue
     forTime:10];
     
     [_violationManager readViolationsFromFileSuccess:^(BOOL isFinished) {
     if (isFinished) {
     _violationsDataSource = [NSMutableArray arrayWithArray:_violationManager.violations];
     
     [_violationsCollectionView reloadData];
     }
     }];
     }
     */
    
    if (_violationManager.isNetworkAvailable) {
        if (cell.violation.state != HRPViolationStateDone && !cell.violation.isUploading && _violationManager.uploadingCount < 2 && [_violationManager canViolationUploadAuto:YES]) {
            [cell showActivityLoader];
            
            [_violationManager uploadViolation:cell.violation
                                    inAutoMode:YES
                                     onSuccess:^(BOOL isSuccess) {
                                         [cell hideActivityLoader];
                                     }];
        }
    }
    
    return cell;
}


#pragma mark - UICollectionViewDelegate -
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showAlertController:indexPath];
}


#pragma mark - UICollectionViewDelegateFlowLayout -
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _violationManager.cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // top, left, bottom, right
    return UIEdgeInsetsZero;
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [[UIApplication sharedApplication] setStatusBarHidden:(size.width < size.height) ? NO : YES];
    
    [_violationManager modifyCellSize:size];
    _currentOrientation = [[UIDevice currentDevice] orientation];
}


#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(HRPCameraController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *videoURL = [[info valueForKey:UIImagePickerControllerReferenceURL] absoluteString];
    BOOL isContinueOn = YES;
    
    // Scroll to first Violation
    if (_violationManager.violations.count > 0)
        [_violationsCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                          atScrollPosition:UICollectionViewScrollPositionTop
                                                  animated:YES];
    
    // Stop Geolocation service
    [picker.locationsService.manager stopUpdatingLocation];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    _imagePickerController = picker;
    
    // Handler Video from Library
    if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.assetsVideoURL contains[cd] %@ OR SELF.assetsVideoURLOriginal contains[cd] %@", videoURL, videoURL];
        NSMutableArray *existingVideos = [NSMutableArray arrayWithArray:[_violationManager.violations filteredArrayUsingPredicate:predicate]];
        
        if (existingVideos.count > 0) {
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert info title", nil)
                              andMessage:NSLocalizedString(@"Alert error video add", nil)];
            
            isContinueOn = NO;
        }
        
        else {
            // Get Video size, Mb
            [_violationManager getVideoSizeFromInfo:info];
            
            // Check Video file size
            [_violationManager checkVideoFileSize];
            
            // Check Video duration (<= 60 sec)
            AVURLAsset *videoFileAsset = [AVURLAsset URLAssetWithURL:[info valueForKey:UIImagePickerControllerReferenceURL] options:nil];
            CMTime duration = videoFileAsset.duration;
            
            if (CMTimeCompare(duration, CMTimeMake(62, 1)) == 1) {
                [self showAlertViewWithTitle:NSLocalizedString(@"Alert info title", nil)
                                  andMessage:NSLocalizedString(@"Alert error video duration", nil)];

                isContinueOn = NO;
            }
        }
    }
    
    if (isContinueOn) {
        HRPViolation *violation = [[HRPViolation alloc] init];
        violation.isTaking = YES;
        
        // Prepare data source
        [_violationsCollectionView performBatchUpdates:^{
            NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
            
            for (int i = 0; i <= _violationManager.violations.count; i++) {
                [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            (_violationManager.violations.count == 0) ? [_violationManager.violations addObject:violation] :
            [_violationManager.violations insertObject:violation atIndex:0];
            
            (_violationManager.images.count == 0) ? [_violationManager.images addObject:[UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage]] : [_violationManager.images insertObject:[UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage] atIndex:0];
            
            [_violationsCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        }
                                            completion:nil];
        
        if  (_violationManager.violations.count == 1)
            [_violationsCollectionView reloadData];
        
        // Save Video to Library
        if (_imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
            violation.latitude = _imagePickerController.latitude;
            violation.longitude = _imagePickerController.longitude;
        }

        [self writeViolation:violation atAssetURL:[info objectForKey:UIImagePickerControllerMediaURL]];
        _imagePickerController = nil;
    }
}

- (void)readMetaDataFromVideoFile:(NSURL *)videoURL forViolation:(HRPViolation *)violation {
    if (videoURL) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *videoAsset) {
            CLLocation *location = [videoAsset valueForProperty:ALAssetPropertyLocation];
            
            if (violation.latitude == 0)
                violation.latitude = (location.coordinate.latitude == 0.f) ? -0.1f : location.coordinate.latitude;
            
            if (violation.longitude == 0)
                violation.longitude = (location.coordinate.longitude == 0.f) ? -0.1f : location.coordinate.longitude;
            
            violation.duration = [[videoAsset valueForProperty:ALAssetPropertyDuration] floatValue];
            
            [self updateViolation:violation atAssetURL:videoURL];
        };
        
        ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror) { };
        
        [library assetForURL:videoURL resultBlock:resultblock failureBlock:failureblock];
    }
}

- (void)writeViolation:(HRPViolation *)violation atAssetURL:(NSURL *)videoURL {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeVideoAtPathToSavedPhotosAlbum:videoURL
                                completionBlock:^(NSURL *assetVideoURL, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (error)
                                            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                                              andMessage:NSLocalizedString(@"Alert error saving video message", nil)];
                                        
                                        else {
                                            [self readMetaDataFromVideoFile:assetVideoURL forViolation:violation];
                                        }
                                    });
                                }];
}

- (void)updateViolation:(HRPViolation *)violation atAssetURL:(NSURL *)assetVideoURL {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    HRPImage *image = [[HRPImage alloc] init];
    image.imageAvatar = [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];
    
    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//    [cell showActivityLoader];
    
    NSError *err = NULL;
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:assetVideoURL options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:videoAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(1, 2);
    CGImageRef oneRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *photoFromVideo = [[UIImage alloc] initWithCGImage:oneRef scale:1.f orientation:UIImageOrientationUp];
    
    // Save Photo from Video to Library
    [library writeImageToSavedPhotosAlbum:photoFromVideo.CGImage
                              orientation:(ALAssetOrientation)photoFromVideo.imageOrientation
                          completionBlock:^(NSURL *assetPhotoURL, NSError *error) {
                              // Modify Violation item
                              violation.assetsVideoURL = [assetVideoURL absoluteString];
                              violation.assetsPhotoURL = [assetPhotoURL absoluteString];
                              image.imageOriginalURL = [assetPhotoURL absoluteString];                              
                              image.imageAvatar = [image squareImageFromImage:photoFromVideo scaledToSize:_violationManager.cellSize.width];

                              [UIView transitionWithView:cell.photoImageView
                                                duration:0.5f
                                                 options:UIViewAnimationOptionTransitionCrossDissolve
                                              animations:^{
                                                  cell.photoImageView.image = image.imageAvatar;
                                                  cell.playVideoImageView.alpha = 1.f;
                                              }
                                              completion:^(BOOL finished) {
                                                  violation.type = HRPViolationTypeVideo;
                                                  violation.date = [NSDate date];
                                                  violation.isTaking = NO;
                                                  
                                                  [_violationManager.violations replaceObjectAtIndex:0 withObject:violation];
                                                  [_violationManager.images replaceObjectAtIndex:0 withObject:image.imageAvatar];
                                                  [_violationManager saveViolationsToFile:_violationManager.violations];
                                                  [cell hideActivityLoader];
                                                  _imagePickerController = nil;
                                              }];
                          }];
}

- (void)imagePickerControllerDidCancel:(HRPCameraController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{ }];
    
    [picker.locationsService.manager stopUpdatingLocation];
    
    picker = nil;
    _imagePickerController = nil;
}

@end
