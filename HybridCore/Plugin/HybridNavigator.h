//
//  HybridNavigator.h
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RJBCommand.h"

@protocol HybridNavigator <PluginExport>

// push一个新页面，根据url定位，传入参数params
JSExportAs(push, - (void)push:(NSString *)url params:(NSDictionary *)params);

JSExportAs(present, - (void)present:(NSString *)url params:(NSDictionary *)params);

- (void)pop;

- (void)popToRoot;

@end

@interface HybridNavigator : NSObject <HybridNavigator>

@end
