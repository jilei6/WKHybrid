//
//  HybridConfig.swift
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

public class HybridConfig {
    /// 路由表文件路径，json文件
    static var routeFilePath: String = "" {
        didSet {
            Router.shared.routeFilePath = routeFilePath
        }
    }
    
    /// 预先打包到App中的资源包路径
    static var resourcePreloadPath: String = "" {
        didSet {
            ResourceManager.shared.resourcePreloadPath = resourcePreloadPath
        }
    }
    
    /// 资源包MD5值的解密秘钥, 若设置了该值则表明启用资源包防篡改校验，
    /// 路由表中的资源包信息中必须带上加密后的MD5值, 加密方式为3DES，秘钥长度24位
    static var encryptionKey: String? = nil
    
    /// 日志等级
    static var logLevel: Logger.LoggerLevel = .Warning {
        didSet {
            LogLevel = logLevel
        }
    }
}
