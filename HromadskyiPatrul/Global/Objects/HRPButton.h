//
//  HRPButton.h
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^didButtonPress)(id item);

IB_DESIGNABLE

@interface HRPButton : UIButton

@property (strong, nonatomic) IBInspectable UIColor *fillColor;
@property (strong, nonatomic) IBInspectable UIColor *borderColor;
@property (assign, nonatomic) IBInspectable CGFloat cornerRadius;
@property (assign, nonatomic) IBInspectable CGFloat borderWidth;

@property (nonatomic, copy) didButtonPress didButtonPress;
- (void)setDidButtonPress:(didButtonPress)didButtonPress;

@end
