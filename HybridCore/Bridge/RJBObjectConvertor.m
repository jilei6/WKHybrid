//
//  RJBObjectConvertor.m
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import "RJBObjectConvertor.h"
#import "RJBCommons.h"
#import <objc/runtime.h>

@interface RJBObjectConvertor()

@property (nonatomic) NSMutableString *js;
@property (nonatomic) NSMutableDictionary<NSString*, NSString*> *exportMethodMaps; // localName -> jsName

@end

@implementation RJBObjectConvertor

+ (NSString *)convertObject:(id)object identifier:(NSString *)identifier {
    RJBObjectConvertor *convertor = [[RJBObjectConvertor alloc] initWithObject:object idenetifier:identifier];
    return [convertor toJs];
}

+ (NSString *)convertClass:(Class)cls identifier:(NSString *)identifier {
    RJBObjectConvertor *convertor = [[RJBObjectConvertor alloc] initWithClass:cls identifier:identifier];
    return [convertor toJs];
}

- (instancetype)initWithObject:(id<PluginExport>)object idenetifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _js = [[NSMutableString alloc] init];
        if ([object conformsToProtocol:objc_getProtocol("PluginExport")]) {
            [self convertObjectToJs:object identifier:identifier];
        } else if ([object isKindOfClass:NSClassFromString(@"NSBlock")]) {
            [self convertBlockToJs:object identifier:identifier];
        }
    }
    return self;
}

- (instancetype)initWithClass:(Class)cls identifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _js = [[NSMutableString alloc] init];
        [self convertClassToJs:cls identifier:identifier];
    }
    return self;
}

#pragma mark - Convertor

// 将实例对象转换成JS
- (void)convertObjectToJs:(id)object identifier:(NSString *)identifier {
    [self convertClassToJs:object_getClass(object) identifier:identifier];
}

- (void)convertClassToJs:(Class)cls identifier:(NSString *)identifier {
    _exportMethodMaps = [[NSMutableDictionary alloc] init];
    [_js appendString:@"{"];
    
    // find out all protocol that inherited from `PluginExport`
    NSMutableArray<Protocol *> *exportProtocols = [NSMutableArray array];
    unsigned int outCount = 0;
    Protocol * __unsafe_unretained *protos = class_copyProtocolList(cls, &outCount);
    for (unsigned int index = 0; index < outCount; ++index) {
        Protocol *proto = protos[index];
        if (protocol_conformsToProtocol(proto, objc_getProtocol("PluginExport"))) {
            [exportProtocols addObject:proto];
        }
    }
    
    // 获取所有bridge到js中的方法
    NSArray<NSDictionary *> *methodInfos = [self fetchMethodInfosFromProtocols:exportProtocols];
    
    NSMutableDictionary *methodMaps = [NSMutableDictionary dictionary]; // jsName -> nativeName
    NSString *clsName = [NSString stringWithUTF8String:class_getName(cls)];
    [_js appendFormat:@"__className:\"%@\",", clsName];
    [_js appendFormat:@"__identifier:\"%@\",", identifier];
    
    // 添加js方法
    for (NSDictionary *nativeMethodInfo in methodInfos) {
        NSString *nativeMethodName = nativeMethodInfo[@"name"];
        NSDictionary *jsMethodInfo = [self convertNativeMethodToJs:nativeMethodName];
        NSMethodSignature *sign = nativeMethodInfo[@"signature"];
        NSString *jsMethodName = jsMethodInfo[@"name"];
        NSString *jsMethodParam = jsMethodInfo[@"paramStr"];
        
        // Export as
        if ([_exportMethodMaps.allKeys containsObject:nativeMethodName]) {
            jsMethodName = _exportMethodMaps[nativeMethodName];
        }
        
        NSString *jsMethodBody = [self jsMethodBodyWithName:jsMethodName signature:sign];
        
        [_js appendFormat:@"%@:function(%@){%@},", jsMethodName, jsMethodParam, jsMethodBody];
        [methodMaps setObject:nativeMethodName forKey:jsMethodName];
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:methodMaps options:NSJSONWritingPrettyPrinted error:nil];
    if (data.length != 0) {
        [_js appendFormat:@"__maps:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    }
    
    [_js appendString:@"}"];
}

// 将block转换成JS
- (void)convertBlockToJs:(id)block identifier:(NSString *)identifier {
    [_js appendString:@"function(){"];
    
    NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:RJB_signatureForBlock(block)];
    NSString *returnType = [[NSString stringWithUTF8String:sign.methodReturnType] substringToIndex:1];
    
    NSString *blockInfo = [NSString stringWithFormat:@"{__identifier: \"%@\", __className: \"NSBlock\"}", identifier];
    NSString *jsBody = [NSString stringWithFormat:@"window.Hybrid.sendCommand(%@, null, %lu, Array.prototype.slice.call(arguments), \"%@\");", blockInfo, sign.numberOfArguments - 1, returnType];
    [_js appendString:jsBody];
    
    [_js appendString:@"}"];
}

- (NSString *)toJs {
    return _js;
}

#pragma mark - Helper

/**
 获取协议中定义的所有方法的名称和返回值类型

 @param protoList 包含Protocol的数组
 @return          方法信息数组，包含两个key: name和signature
 */
- (NSArray<NSDictionary *> *)fetchMethodInfosFromProtocols:(NSArray<Protocol *> *)protoList {
    NSMutableArray<NSDictionary *> *methods = [NSMutableArray array];
    for(Protocol *proto in protoList) {
        NSArray *isRequire = @[@(YES), @(YES), @(NO), @(NO)];
        NSArray *isInstance = @[@(YES), @(NO), @(YES), @(NO)];
        unsigned int count = 0;
        
        for (int index = 0; index < 4; ++index) {
            struct objc_method_description *desList = protocol_copyMethodDescriptionList(proto, [isRequire[index] boolValue], [isInstance[index] boolValue], &count);
            
            for (int desIndex = 0; desIndex < count; ++desIndex) {
                struct objc_method_description des = desList[desIndex];
                NSString *methodName = [NSString stringWithUTF8String:sel_getName(des.name)];
                NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:des.types];
                if ([methodName containsString:@"__JS_EXPORT_AS__"]) {
                    NSArray *arr = [methodName componentsSeparatedByString:@"__JS_EXPORT_AS__"];
                    if (arr.count == 2) { // first: original name, last: exported name
                        _exportMethodMaps[arr.firstObject] = [self convertNativeMethodToJs:arr.lastObject][@"name"];
                        continue;
                    }
                }
                [methods addObject:@{@"name": methodName, @"signature": sign}];
            }
            free(desList);
        }
    }
    return [methods copy];
}

- (NSString *)jsMethodBodyWithName:(NSString *)methodName signature:(NSMethodSignature *)sign {
    NSString *retType = [[NSString stringWithUTF8String:sign.methodReturnType] substringToIndex:1];
    return [NSString stringWithFormat:@"window.Hybrid.sendCommand(this, \"%@\", %lu,  Array.prototype.slice.call(arguments),'%@');", methodName, sign.numberOfArguments - 2, retType];
}

/**
 将native方法转换成对应的js方法

 @param nativeMethod native方法名
 @return 返回一个字典，包括两个key: `name`和`paramStr`(如果有参数)
 */
- (NSDictionary *)convertNativeMethodToJs:(NSString *)nativeMethod {
    NSArray<NSString *> *componenet = [nativeMethod componentsSeparatedByString:@":"];
    if (componenet.count == 0) {
        return @{@"name": nativeMethod};
    }
    
    NSMutableString *methodName = [NSMutableString string];
    NSMutableArray *params = [NSMutableArray array];
    [methodName appendString:componenet[0]];
    
    // 参数名组装在一起作为js的方法名
    for (int index = 1; index < componenet.count; ++index) {
        [methodName appendString:[self capitalizedFirst:componenet[index]]];
        [params addObject:[NSString stringWithFormat:@"p%d", index]];
    }
    
    // 参数
    NSMutableString *paramStr = [NSMutableString string];
    for (int index = 0; index < params.count; ++index) {
        NSString *param = params[index];
        [paramStr appendString:param];
        if (index != params.count - 1) {
            [paramStr appendString:@","];
        }
    }
    
    return @{@"name": methodName, @"paramStr": paramStr};
}

/**
 将字符串的首字母大写

 @param string 原字符串
 @return       处理后的字符创
 */
- (NSString *)capitalizedFirst:(NSString *)string {
    if (string.length == 0) {
        return string;
    }
    NSString *first = [string substringWithRange:NSMakeRange(0, 1)];
    NSString *left = [string substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", [first uppercaseString], left];
}

@end
