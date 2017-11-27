//
//  WebappItem.swift
//  Hybrid
//
//  Created by jilei on 2017/4/24.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

internal struct WebappItem {
    
    /// 资源包的路由URL
    public var routeUrl: String = ""

    /// 解压后的本地保存位置
    public var localPath: String = ""
    
    /// 本地保存位置的URL
    public var localUrl: URL {
        return URL(fileURLWithPath: localPath)
    }
    
    /// 资源包的版本
    public var version: String = ""
}
