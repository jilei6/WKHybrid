//
//  RJBCommand.h
//  ReflectJavascriptBridge
//
//  Created by jilei on 2017/1/22.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RJBCommons.h"
#import "ReflectJavascriptBridge.h"

@interface RJBCommand : NSObject

@property (nonatomic) NSString *identifier; // 该command对应的对象实例ID

/**
 创建一条指令
 
 @param dic 包含Command所需的所有信息
 @return    返回创建的待执行的command
 */
+ (RJBCommand *)commandWithDic:(NSDictionary *)dic;

/**
 执行一条指令

 @param instance 执行该指令的实例对象
 */
- (void)execWithInstance:(id)instance bridge:(ReflectJavascriptBridge *)bridge;

@end
