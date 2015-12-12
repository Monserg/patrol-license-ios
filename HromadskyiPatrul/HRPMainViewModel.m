//
//  HRPMainViewModel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPMainViewModel.h"
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>


@implementation HRPMainViewModel

#pragma mark - Constructors -
- (instancetype)init {
    self            =   [super init];
    
    if (self) {
        _userApp    =   [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}


#pragma mark - API -
- (void)userLoginParameters:(NSString *)email
                  onSuccess:(void(^)(NSDictionary *successResult))success
                  orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    // tested local URL: http://192.168.0.29/app_dev.php/
    AFHTTPRequestOperationManager *requestOperationDomainManager    =   [[AFHTTPRequestOperationManager alloc]
                                                                         initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
    
    NSString *pathAPI                                               =   @"api/register";
    
    AFHTTPRequestSerializer *userRequestSerializer                  =   [AFHTTPRequestSerializer serializer];
    [userRequestSerializer setValue:@"application/json" forHTTPHeaderField:@"CONTENT_TYPE"];
    
    [requestOperationDomainManager POST:pathAPI
                             parameters:@{ @"email" : email }
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if (operation.response.statusCode == 200)
                                        success(responseObject);
                                }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    if (operation.response.statusCode == 400)
                                        failure(operation);
                                }];
}

#pragma mark - Methods -

@end