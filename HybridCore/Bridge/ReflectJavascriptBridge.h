//
//  ReflectJavascriptBridge.h
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "RJBCommons.h"

@interface ReflectJavascriptBridge : NSObject

@property (nonatomic) BOOL logEnable;

/**
 初始化ReflectJavascriptBridge对象

 @param webView  bridge的目标webView, 支持`UIWebView`和`WKWebView`
 @param delegate webView的delegate对象
 @return         返回创建的的ReflectJavascriptBridge实例
 */
+ (ReflectJavascriptBridge *)bridge:(id)webView delegate:(id)delegate;

/**
 初始化ReflectJavascriptBridge对象

 @param webView bridge的目标webView
 @return        返回创建的的ReflectJavascriptBridge实例
 */
+ (ReflectJavascriptBridge *)bridge:(id)webView;

/**
 执行JS代码并返回执行结果

 @param js      JS代码
 @param handler 执行结果回调，在`UIWebView`中是同步的，在`WKWebView`中是异步
 */
- (void)callJs:(NSString *)js completionHandler:(void(^)(id result, NSError *error))handler;

/**
 根据名字调用JS中的方法，并指定任意数量的参数，该方法需在JS代码中注册
 
 @param methodName 在JS中注册的方法的名称
 @param args       任意数量的参数
 @param handler    执行结果回调，在`UIWebView`中是同步的，在`WKWebView`中是异步
 */
- (void)callJsMethod:(NSString *)methodName withArgs:(NSArray *)args completionHandler:(void(^)(id result, NSError *error))handler;

// Subscript
//- (id)objectForKeyedSubscript:(id)key;
//
//- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey;
//
//- (void)register:(id)object forKey:(NSString *)key;

//- (id)objectForKey:(NSString *)key;

@end
