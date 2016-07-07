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
//  HRPCameraController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 24.03.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "HRPLocations.h"


@interface HRPCameraController : UIImagePickerController <CLLocationManagerDelegate>

@property (strong, nonatomic) HRPLocations *locationsService;
@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;

- (void)startUpdateLocations;

@end
