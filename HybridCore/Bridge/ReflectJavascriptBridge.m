//
//  ReflectJavascriptBridge.m
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import "ReflectJavascriptBridge.h"
#import "RJBCommons.h"
#import "RJBObjectConvertor.h"
#import "RJBCommand.h"
#import <objc/runtime.h>
#import "Hybrid-Swift.h"
#import "PluginInstance.h"

@interface ReflectJavascriptBridge() <UIWebViewDelegate, WKNavigationDelegate>

//@property (nonatomic) NSMutableDictionary<NSString *, id> *reflectObjects; 
//@property (nonatomic) NSMutableDictionary<NSString *, id> *waitingObjects; // wait for bridge
@property (nonatomic) NSMutableDictionary<NSString *, id> *bridgedBlocks;

@property (nonatomic) NSMutableArray<RJBCommand *> *commands;
@property (nonatomic) NSMutableDictionary<NSString *, PluginInstance *> *plugins;

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic) id<WKNavigationDelegate> delegate;
@property (nonatomic) BOOL injectJsFinished;

@end

@implementation ReflectJavascriptBridge

+ (ReflectJavascriptBridge *)bridge:(WKWebView *)webView delegate:(id<WKNavigationDelegate>)delegate {
    return [[ReflectJavascriptBridge alloc] initWithWebView:webView delegate:delegate];
}

+ (ReflectJavascriptBridge *)bridge:(id)webView {
    return [ReflectJavascriptBridge bridge:webView delegate:nil];
}

- (instancetype)initWithWebView:(WKWebView *)webView delegate:(id<WKNavigationDelegate>)delegate {
    self = [super init];
    if (self) {
        _webView = webView;
        _delegate = delegate;
        _webView.navigationDelegate = self;
        
//        _reflectObjects = [NSMutableDictionary dictionary];
//        _waitingObjects = [NSMutableDictionary dictionary];
        _bridgedBlocks = [NSMutableDictionary dictionary];
        _commands = [NSMutableArray array];
        
        _plugins = [NSMutableDictionary dictionary];
        NSArray<PluginInstance *> *list = [[PluginLoader shared] loadPlugins];
        for (PluginInstance *instance in list) {
            _plugins[instance.pluginName] = instance;
        }
    }
    return self;
}

- (void)callJs:(NSString *)js completionHandler:(void (^)(id, NSError *))handler {
    [_webView evaluateJavaScript:js completionHandler:handler];
}

- (void)callJsMethod:(NSString *)methodName withArgs:(NSArray *)args completionHandler:(void (^)(id, NSError *))handler {
    if (!self.injectJsFinished) {
        Hybrid_LogWarning(@"Javascript initialize not complete!");
        if (handler != nil) {
            handler(nil, [NSError errorWithDomain:@"javascript initialize not complete!" code:0 userInfo:nil]);
        }
    }
    
    NSMutableString *paramStr = [NSMutableString string];
    for (id param in args) {
        if ([param isKindOfClass:[NSString class]]) {
            [paramStr appendFormat:@"\"%@\",", (NSString *)param];
        } else if ([param isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber *)param;
            [paramStr appendFormat:@"%@,", number];
        }
    }
    
    NSString *js = nil;
    if (paramStr.length > 0) {
        NSString *param = [paramStr substringToIndex:paramStr.length - 1]; // delete the last comma
        js = [NSString stringWithFormat:@"window.Hybrid.checkAndCall(\"%@\",[%@]);", methodName, param];
    } else {
        js = [NSString stringWithFormat:@"window.Hybrid.checkAndCall(\"%@\");", methodName];
    }
    
    [_webView evaluateJavaScript:js completionHandler:handler];
}

- (void)setLogEnable:(BOOL)logEnable {
    rjb_logEnable = logEnable;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([navigationAction.request.URL.scheme isEqualToString:RJBScheme]) {
        if ([navigationAction.request.URL.host isEqualToString:RJBInjectJs]) {
            [self injectJs];
        } else if ([navigationAction.request.URL.host isEqualToString:RJBReadyForMessage]) {
            [self fetchQueueingCommands];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    if ([_delegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_delegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - Private method

/**
 向JS中注册一个Native对象

 @param obj  native的对象实例或block
 @param name 实例名称
 */
- (void)bridgeObjectToJs:(id)obj name:(NSString *)name {
    NSString *jsObj = [self convertNativeObjectToJs:obj identifier:name];
    NSString *js = [NSString stringWithFormat:@"window.Hybrid.addObject(%@,\"%@\");", jsObj, name];
    [self callJs:js completionHandler:nil];
}

/**
 将一个native对象转换成JS对象的表示

 @param object native对象实例
 @return       一段描述JS对象的JS代码
 */
- (NSString *)convertNativeObjectToJs:(id)object identifier:(NSString *)identifier {
    NSString *jsObject = [RJBObjectConvertor convertObject:object identifier:identifier];
    return jsObject;
}

/**
 从JS中获取待执行的command对象
 */
- (void)fetchQueueingCommands {
    [self callJs:@"window.Hybrid.dequeueCommandQueue();" completionHandler:^(id result, NSError *error) {
        NSString *json = (NSString *)result;
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSArray *commandArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            if (commandArray != nil) {
                for (NSDictionary *commandInfo in commandArray) {
                    RJBCommand *command = [RJBCommand commandWithDic:commandInfo];
                    if (command != nil) {
                        [_commands addObject:command];
                    }
                }
            }
            
            [self execCommands];
        }
    }];
}

/**
 执行所有队列中的command
 */
- (void)execCommands {
    if (_commands.count == 0) {
        return;
    }
    
    for (RJBCommand *command in _commands) {
        [command execWithInstance:_plugins[command.identifier].instance bridge:self];
    }
    // TODO: 执行结束清空commands, 暂时先同步执行
    [_commands removeAllObjects];
}

/**
 向webView中注入JS代码
 */
- (void)injectJs {
    [self callJs:ReflectJavascriptBridgeInjectedJS() completionHandler:^(id result, NSError *error) {
        if (!error) {
            _injectJsFinished = YES;
//            [_waitingObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<PluginExport>  _Nonnull obj, BOOL * _Nonnull stop) {
//                [self setObject:obj forKeyedSubscript:key];
//            }];
//            [_waitingObjects removeAllObjects];
            
            typeof(self) weakSelf = self;
            [_plugins enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, PluginInstance * _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *js = [NSString stringWithFormat:@"window.Hybrid.addObject(%@,\"%@\");", obj.bridgedJs, obj.pluginName];
                [weakSelf callJs:js completionHandler:^(id result, NSError *error) {
                    if (error) {
                        Hybrid_LogError(@"Bridge %@ error: %@", key, error);
                    }
                }];
            }];
        } else {
            Hybrid_LogError(@"Inject js code fail: %@", error);
        }
    }];
}


#pragma mark - Subscript

//- (id)objectForKeyedSubscript:(id)key {
//    if ([key isKindOfClass:[NSString class]] == NO) {
//        return nil;
//    }
//    return _reflectObjects[key];
//}
//
//- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey {
//    if (![object conformsToProtocol:objc_getProtocol("PluginExport")] && ![object isKindOfClass:NSClassFromString(@"NSBlock")]) {
//        Hybrid_LogError(@"Object should be a `Block` or an class instance confirms to `PluginExport`");
//        return;
//    }
//    
//    if (_injectJsFinished) {
//        _reflectObjects[aKey] = object;
//        [self bridgeObjectToJs:object name:(NSString *)aKey];
//    } else {
//        _waitingObjects[aKey] = object;
//    }
//}

//- (void)register:(id)object forKey:(NSString *)key {
//    [self setObject:object forKeyedSubscript:key];
//}
//
//- (id)objectForKey:(NSString *)key {
//    return [self objectForKeyedSubscript:key];
//}

@end
