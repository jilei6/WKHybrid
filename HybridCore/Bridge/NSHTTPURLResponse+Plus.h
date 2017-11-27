//
//  NSHTTPURLResponse+Plus.h
//  TheOnePlus
//
//  Created by admin on 2017/7/20.
//  Copyright © 2017年 Jaren. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSHTTPURLResponse (Plus)

/**
 Returns a new http response. If `noAccessControl` = YES, set CORS disabled.
 */
+ (nullable instancetype)rxr_responseWithURL:(NSURL *)url
                                  statusCode:(NSInteger)statusCode
                                headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                             noAccessControl:(BOOL)noAccessControl;

@end

NS_ASSUME_NONNULL_END
