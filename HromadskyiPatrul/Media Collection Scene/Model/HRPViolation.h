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
//  HRPViolation.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.02.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM (NSInteger, HRPViolationState) {
    HRPViolationStateDone,
    HRPViolationStateRepeat,
    HRPViolationStateUpload
};

typedef NS_ENUM (NSInteger, HRPViolationType) {
    HRPViolationTypePhoto,
    HRPViolationTypeVideo
};


@interface HRPViolation : NSObject

@property (assign, nonatomic) HRPViolationState state;
@property (assign, nonatomic) HRPViolationType type;
@property (strong, nonatomic) NSString *assetsPhotoURL;
@property (strong, nonatomic) NSString *assetsVideoURL;
@property (strong, nonatomic) NSString *assetsVideoURLOriginal;
@property (strong, nonatomic) NSDate *date;
@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) CGFloat duration;
@property (assign, nonatomic) BOOL isUploading;
@property (assign, nonatomic) BOOL isTaking;

@end
