//
//  RJBCommand.m
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import "RJBCommand.h"
#import "RJBCommons.h"
#import <objc/runtime.h>
#import "Hybrid-Swift.h"

#define NumberType (0)
#define StringType (1)
#define ObjectType (2)
#define FunctionType (3)
#define Type (@"type")
#define Data (@"data")

#define PARAM_ERROR() \
    Hybrid_LogError(@"类:%@, 方法:%@, 参数类型错误", _className, _methodName);\
    return;

@interface RJBCommand()

@property (nonatomic) NSString *className;
@property (nonatomic) NSString *methodName;
@property (nonatomic, copy) NSArray *args;
@property (nonatomic) NSString *returnType;
@property (nonatomic) NSString *callbackId;

@end

@implementation RJBCommand

+ (RJBCommand *)commandWithDic:(NSDictionary *)dic {
    NSString *clsName = dic[@"className"];
    NSString *method = dic[@"method"];
    NSString *identifier = dic[@"identifier"];
    NSArray *args = dic[@"args"];
    NSString *returnType = dic[@"returnType"];
    NSString *callbackId = dic[@"callbackId"];
    

    BOOL isBlock = [clsName isEqualToString:@"NSBlock"];
    if (clsName.length == 0 || (method.length == 0 && !isBlock)) {
        return nil;
    }
    
    // 类不存在
    Class cls = objc_getClass([clsName cStringUsingEncoding:NSUTF8StringEncoding]);
    if (cls == nil) {
        Hybrid_LogError(@"Class `%@` not exists!", clsName);
        return nil;
    }

    return [[RJBCommand alloc] initWithClass:clsName
                                      method:method
                                  identifier:identifier
                                        args:args
                                  returnType:returnType
                                  callbackId:callbackId];
}

- (void)execWithInstance:(id)instance bridge:(ReflectJavascriptBridge *)bridge {
    NSInvocation *invocation = nil;
    NSMethodSignature *sign = nil;
    NSInteger paramOffset;
    
    NSMutableArray<RJBCallback> *argBlocks = [[NSMutableArray alloc] init];
    
    if ([_className isEqualToString:@"NSBlock"]) {
        sign = [NSMethodSignature signatureWithObjCTypes:RJB_signatureForBlock(instance)];
        invocation = [NSInvocation invocationWithMethodSignature:sign];
        invocation.target = instance;
        paramOffset = 1;
    } else {
        // 查找方法
        SEL selector = NSSelectorFromString(_methodName);
        paramOffset = 2;
        sign = [[instance class] instanceMethodSignatureForSelector:selector];
        if (sign) { // 存在实例方法
            invocation = [NSInvocation invocationWithMethodSignature:sign];
            invocation.target = instance;
        } else { // 否则查找类方法
            sign = [[instance class] methodSignatureForSelector:selector];
            if (sign) {
                invocation = [NSInvocation invocationWithMethodSignature:sign];
                invocation.target = [instance class];
            } else {
                Hybrid_LogError(@"Method '%@' not implement in class '%@'", _methodName, _className);
                return;
            }
        }
        invocation.selector = selector;
    }
    
    // 设置参数
    for (NSInteger paramIndex = paramOffset; paramIndex < [sign numberOfArguments]; ++paramIndex) {
        if (_args.count <= paramIndex - paramOffset) {
            break;
        }
        
        NSDictionary *argInfo = (NSDictionary *)_args[paramIndex - paramOffset];
        NSString *type = [NSString stringWithUTF8String:[sign getArgumentTypeAtIndex:paramIndex]]; // expected type
        
        switch ([argInfo[Type] integerValue]) {
            case NumberType: // 数字类型
                if (RJB_isInteger(type) || RJB_isUnsignedInteger(type)) {
                    long long param = [argInfo[Data] longLongValue];
                    [invocation setArgument:&param atIndex:paramIndex];
                } else if (RJB_isFloat(type)) {
                    float param = [argInfo[Data] doubleValue];
                    [invocation setArgument:&param atIndex:paramIndex];
                } else if (RJB_isDouble(type)) {
                    double param = [argInfo[Data] doubleValue];
                    [invocation setArgument:&param atIndex:paramIndex];
                } else {
                    PARAM_ERROR();
                }
                break;
            case StringType: // 字符串
                if (RJB_isClass(type)) {
                    NSString *param = (NSString *)argInfo[Data];
                    [invocation setArgument:&param atIndex:paramIndex];
                } else {
                    PARAM_ERROR();
                }
                break;
            case ObjectType: // 数组或字典
                if (RJB_isClass(type)) {
                    NSData *jsonData = [argInfo[Data] dataUsingEncoding:NSUTF8StringEncoding];
                    id param = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
                    if (param) {
                        [invocation setArgument:&param atIndex:paramIndex];
                    } else {
                        PARAM_ERROR();
                    }
                } else {
                    PARAM_ERROR();
                }
                break;
            case FunctionType: // 闭包
                if (RJB_isClass(type)) { // block类型
                    NSString *callbackId = (NSString *)argInfo[Data];
                    __weak typeof(self) weakSelf = self;
                    RJBCallback block = ^(NSArray *params) {
                        __strong typeof(self) strongSelf = weakSelf;
                        [strongSelf callbackToJs:bridge callbackId:callbackId params:params];
                    };
                    [argBlocks addObject:block]; // 防止block被释放
                    
                    [invocation setArgument:&block atIndex:paramIndex];
                } else {
                    PARAM_ERROR();
                }
                break;
            default:
                break;
        }
    }
    
    // 执行方法
    [invocation invoke];
    
    // 接收返回值
    if (![_returnType isEqualToString:@"v"] && _callbackId != nil) {
        NSString *value = nil;
        if ([_returnType isEqualToString:@"@"]) {
            __unsafe_unretained id ret = nil;
            [invocation getReturnValue:&ret];
            value = [NSString stringWithFormat:@"%@", ret];
        } else if ([_returnType isEqualToString:@"f"]) {
            float ret = 0;
            [invocation getReturnValue:&ret];
            value = [NSString stringWithFormat:@"%g", ret];
        } else if ([_returnType isEqualToString:@"d"]) {
            double ret = 0;
            [invocation getReturnValue:&ret];
            value = [NSString stringWithFormat:@"%g", ret];
        } else {
            long long ret = 0;
            [invocation getReturnValue:&ret];
            value = [NSString stringWithFormat:@"%lld", ret];
        }
        
        if (_callbackId) {
            [self callbackToJs:bridge callbackId:_callbackId params:@[value]];
        }
    }
}

// 调用JS环境中的回调方法
- (void)callbackToJs:(ReflectJavascriptBridge *)bridge callbackId:(NSString *)callbackId params:(NSArray *)params {
    NSMutableString *value = [@"[" mutableCopy];
    for (id param in params) {
        if ([param isKindOfClass:[NSString class]]) {
            [value appendFormat:@"\"%@\"", param];
        } else if ([param isKindOfClass:[NSNumber class]]) {
            [value appendFormat:@"%@", param];
        } else {
            Hybrid_LogWarning(@"`RJBCallback`的参数只支持`NSString`和`NSNumber`类型");
        }
    }
    [value appendString:@"]"];

    NSString *callbackJs = [NSString stringWithFormat:@"window.Hybrid.callback(\"%@\",%@);", callbackId, value];
    [bridge callJs:callbackJs completionHandler:nil];
}

- (instancetype)initWithClass:(NSString *)className
                       method:(NSString *)methodName
                   identifier:(NSString *)identifier
                         args:(NSArray *)args
                   returnType:(NSString *)returnType
                   callbackId:(NSString *)callbackId {
    self = [super init];
    if (self) {
        _className = className;
        _methodName = methodName;
        _identifier = identifier;
        _args = args;
        _returnType = returnType;
        _callbackId = callbackId;
    }
    return self;
}

@end
