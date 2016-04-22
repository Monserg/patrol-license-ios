//
//  HRPVideoPlayerViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 15.10.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoPlayerViewController.h"
#import "HRPVideoPreview.h"


@interface HRPVideoPlayerViewController ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewTopConstraint;

@end


@implementation HRPVideoPlayerViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Preview a Video", nil);
    
    self.player = [AVPlayer playerWithURL:_videoURL];
    self.player.volume = [[AVAudioSession sharedInstance] outputVolume];
    
    [self setAudioVolume];
    
    [self.playerView setMovieToPlayer:self.player];
    [self.player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.player = nil;
    self.playerView = nil;
}

#pragma mark - Methods -
- (void)setAudioVolume {
    AVAsset *avAsset = [[self.player currentItem] asset] ;
    NSArray *audioTracks = [avAsset tracksWithMediaType:AVMediaTypeAudio] ;
    NSMutableArray *allAudioParams = [NSMutableArray array] ;
    
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters] ;
        [audioInputParams setVolume:1.f atTime:kCMTimeZero] ;
        [audioInputParams setTrackID:[track trackID]] ;
        [allAudioParams addObject:audioInputParams];
    }
    
    AVMutableAudioMix *audioVolMix = [AVMutableAudioMix audioMix] ;
    [audioVolMix setInputParameters:allAudioParams];
    [[self.player currentItem] setAudioMix:audioVolMix];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        self.statusViewTopConstraint.constant = -20.f;
    
    else
        self.statusViewTopConstraint.constant = 0.f;
}

@end
