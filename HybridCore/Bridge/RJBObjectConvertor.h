//
//  RJBObjectConvertor.h
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RJBCommons.h"

@interface RJBObjectConvertor : NSObject

/**
 将native实例转换成js对象的描述

 @param object     native对象实例
 @param identifier 实例对象的名称
 @return           描述一个JS对象的JS代码
 */
+ (NSString *)convertObject:(id)object identifier:(NSString *)identifier;

/**
 将一个Native类转换成js描述

 @param cls        实现了`PluginExport`的类
 @param identifier 插件名
 @return           返回js代码
 */
+ (NSString *)convertClass:(Class)cls identifier:(NSString *)identifier;

@end
