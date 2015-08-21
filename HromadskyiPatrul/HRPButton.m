//
//  HRPButton.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPButton.h"

@implementation HRPButton

#pragma mark - Methods -
- (void)setFillColor:(UIColor *)fillColor {
    self.layer.backgroundColor  =   fillColor.CGColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius     =   cornerRadius;
}

@end
