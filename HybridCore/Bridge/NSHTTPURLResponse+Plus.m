//
//  NSHTTPURLResponse+Plus.m
//  TheOnePlus
//
//  Created by admin on 2017/7/20.
//  Copyright © 2017年 Jaren. All rights reserved.
//

#import "NSHTTPURLResponse+Plus.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSHTTPURLResponse (Plus)

+ (nullable instancetype)rxr_responseWithURL:(NSURL *)url
                                  statusCode:(NSInteger)statusCode
                                headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                             noAccessControl:(BOOL)noAccessControl
{
  if (!noAccessControl) {
    return [[NSHTTPURLResponse alloc] initWithURL:url statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
  }

  NSMutableDictionary<NSString *, NSString *> *mutableHeaderFields = [NSMutableDictionary<NSString *, NSString *> dictionary];
  [mutableHeaderFields setValue:@"*" forKey:@"Access-Control-Allow-Origin"];
  [mutableHeaderFields setValue:@"Origin, X-Requested-With, Content-Type" forKey:@"Access-Control-Allow-Headers"];

  if (headerFields != nil && [headerFields count] > 0) {
    [mutableHeaderFields addEntriesFromDictionary:headerFields];
  }

  return [[NSHTTPURLResponse alloc] initWithURL:url statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:mutableHeaderFields];
}

@end

NS_ASSUME_NONNULL_END

