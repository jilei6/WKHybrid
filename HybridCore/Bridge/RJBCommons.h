//
//  RJBCommons.h
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/23.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef JSExoprtAs
#define JSExportAs(PropertyName, Selector) \
@optional Selector __JS_EXPORT_AS__##PropertyName:(id)argument; @required Selector
#endif

#define Hybrid_LogVerbose(...) [Logger LogVerbose:[NSString stringWithFormat:__VA_ARGS__]];

#define Hybrid_LogWarning(...) [Logger LogWarning:[NSString stringWithFormat:__VA_ARGS__]];

#define Hybrid_LogError(...) [Logger LogError:[NSString stringWithFormat:__VA_ARGS__]];

/// Native给JS的回调
typedef void (^RJBCallback)(NSArray *params);

static NSString *const RJBScheme = @"reflectjavascriptbridge";
static NSString *const RJBReadyForMessage = @"_ReadyForCommands_";
static NSString *const RJBInjectJs = @"_InjectJs_";
static NSString *const RJBBlockClassName = @"_NativeBlock_";

static BOOL rjb_logEnable = YES;

@protocol PluginExport <NSObject>

@optional
- (void)setup; // 实现该方法以完成插件的初始化
+ (NSString *)pluginName; // 实现该方法以自定义插件名称，默认名称为插件的类名

@end

// the js code to inject
NSString *ReflectJavascriptBridgeInjectedJS();

// 获取block的签名
const char *RJB_signatureForBlock(id block);

// 检测类型编码type是否为整型类型
BOOL RJB_isInteger(NSString *type);

// 检测类型编码type是否为无符号整型
BOOL RJB_isUnsignedInteger(NSString *type);

// 检测类型编码type是否为单精度浮点类型
BOOL RJB_isFloat(NSString *type);

// 检测类型编码type是否为双精度浮点类型
BOOL RJB_isDouble(NSString *type);

// 类型编码type是否为类
BOOL RJB_isClass(NSString *type);
