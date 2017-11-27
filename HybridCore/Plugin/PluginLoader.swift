//
//  PluginLoader.swift
//  Hybrid
//
//  Created by jilei on 2017/4/6.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

internal class PluginLoader: NSObject {
    
    // MARK: - Public
    
    /// 单例对象
    public static let shared = PluginLoader()
    
    /// 加载并返回所有插件
    ///
    /// - Returns: 包含所有插件的数组
    public func loadPlugins() -> [PluginInstance] {
        if !autoLoadFinished {
            autoLoadPlugin()
        }
        
//        return basePlugins.map({ (instance) -> PluginInstance in
//            return instance.copy() as! PluginInstance
//        })
        return basePlugins
    }
    
    // MARK: - Private
    
    /// 插件列表
    fileprivate var basePlugins: [PluginInstance] = []
    
    /// 所有插件已加载完毕
    fileprivate var autoLoadFinished = false
    
    /// 自动加载所有插件
    fileprivate func autoLoadPlugin() {
        var count: UInt32 = 0
        if let classList = objc_copyClassList(&count) {
            for index in 0..<numericCast(count) {
                if let cls = classList[index], class_conformsToProtocol(cls, PluginExport.self) {
                    basePlugins.append(PluginInstance(with: cls))
                }
            }
        }
        autoLoadFinished = true
    }
}
