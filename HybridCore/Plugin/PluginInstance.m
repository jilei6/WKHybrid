//
//  PluginInstance.m
//  Hybrid
//
//  Created by jilei on 2017/4/6.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import "PluginInstance.h"
#import "RJBObjectConvertor.h"
#import <objc/runtime.h>

@interface PluginInstance()

@property (nonatomic) Class pluginClass;

@end

@implementation PluginInstance

@synthesize instance = _instance;
@synthesize bridgedJs = _bridgedJs;

+ (PluginInstance *)instanceWithClass:(Class)pluginClass {
    return [[PluginInstance alloc] initWithClass:pluginClass];
}

- (instancetype)initWithClass:(Class)pluginClass {
    self = [super init];
    if (self) {
        _pluginClass = pluginClass;
        _isInitialized = NO;
        
        // 获取插件名字
        SEL nameSel = @selector(pluginName);
        if (class_respondsToSelector(object_getClass(_pluginClass), nameSel)) {
            NSMethodSignature *sign = [_pluginClass methodSignatureForSelector:nameSel];
            if (strcmp([sign methodReturnType], "@") == 0) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
                invocation.target = _pluginClass;
                invocation.selector = nameSel;
                [invocation invoke];
                
                __unsafe_unretained id ret = nil;
                [invocation getReturnValue:&ret];
                _pluginName = (NSString *)ret;
            }
        } else {
            NSString *clsName = [NSString stringWithUTF8String:class_getName(_pluginClass)];
            _pluginName = [[clsName componentsSeparatedByString:@"."] lastObject];
        }
    }
    return self;
}

- (instancetype)initWithClass:(Class)pluginClass pluginName:(NSString *)name bridgedJs:(NSString *)js {
    self = [self initWithClass:pluginClass];
    if (self) {
        _pluginName = name;
        _bridgedJs = js;
    }
    return self;
}

- (id<PluginExport>)instance {
    if (!_instance) {
        _instance = [_pluginClass new];
        if ([_instance respondsToSelector:@selector(setup)]) {
            [_instance setup];
        }
    }
    
    return _instance;
}

- (NSString *)bridgedJs {
    if (!_bridgedJs) {
        _bridgedJs = [RJBObjectConvertor convertClass:_pluginClass identifier:_pluginName];
    }
    
    return _bridgedJs;
}

@end
