//
//  Util.swift
//  Hybrid
//
//  Created by jilei on 2016/12/12.
//  Copyright © 2016年 jilei. All rights reserved.
//

import UIKit
import objective_zip

enum Errors: Error {
    case readDataFail
    case httpRequestError
}

internal class Util {
    
    struct Constant {
        static let webappInfoFile = "webapp_info.json"
    }
    
    // MARK: - 获取文件夹路径
    
    /// 获取Application Support文件夹路径
    class var appSpportPath: URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first else {
            return nil
        }
        
        if FileManager.default.fileExists(atPath: path) == false {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                LogError("error occured when create \(path) error: \(error)")
            }
        }
         LogError("fileURLWithPath: '\(path)'")
        return URL(fileURLWithPath: path)
    }
    
    /// 获取'Application Support/Hybrid'路径
    class var rootPath: URL? {
        if let url = appSpportPath?.appendingPathComponent("Hybrid") {
                 
            if Util.createDirectoryIfNotExist(withPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    /// 获取'Application Support/Hybrid/webapp'路径, 保存资源包解压后的文件夹
    class var webappPath: URL? {
        if let url = appSpportPath?.appendingPathComponent("Hybrid").appendingPathComponent("webapp") {
            if Util.createDirectoryIfNotExist(withPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    /// 获取'Application Support/Hybrid/temp'路径, 用于临时保存资源包
    class var webappTempPath: URL? {
        if let url = appSpportPath?.appendingPathComponent("Hybrid").appendingPathComponent("temp") {
            if Util.createDirectoryIfNotExist(withPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    /// 获取临时文件夹
    class var tempPath: String {
        return NSTemporaryDirectory()
    }
    
    // MARK: - 创建文件和文件夹
    
    /// 创建文件夹
    ///
    /// - Parameter path: 文件夹路径
    /// - Returns: 是否创建成功
    @discardableResult class func createDirectoryIfNotExist(withPath path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) == false {
        
            
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                LogError("Create directory at '\(path)' failed: \(error)")
                return false
            }
        }
        return true
    }
    
    /// 创建文件
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否创建成功
    class func createFileIfNotExist(withPath path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) == false {
            if FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) == false {
                LogError("Create file at '\(path)' failed")
                return false
            }
        }
        return true
    }
    
    // MARK: - 读取
    
    /// 解压文件，覆盖目标路径的相同文件
    ///
    /// - Parameters:
    ///   - zipPath: 压缩包位置
    ///   - toPath:  解压位置
    /// - Returns:   成功则返回true，否则返回false
    @discardableResult class func unzip(from zipPath: URL, to toPath: URL) -> Bool {
        if FileManager.default.fileExists(atPath: toPath.path) {
            do {
                try FileManager.default.removeItem(at: toPath)
            } catch {
                return false
            }
        }
       
        
        Util.createDirectoryIfNotExist(withPath: toPath.path) // 创建目标文件夹
        
        let zipFile = OZZipFile(fileName: zipPath.path, mode: .unzip)
        zipFile.goToFirstFileInZip()
        
        repeat {
            let fileInfo = zipFile.getCurrentFileInZipInfo()
            if fileInfo.name.hasPrefix("__MACOSX/") {
                continue
            }
            
            let targetPath = toPath.appendingPathComponent(fileInfo.name)
            // 文件夹
            NSLog("fileInfo.name---%@", fileInfo.name);
            if fileInfo.name.contains("/") && fileInfo.name.contains(".")  {
                //Util.createDirectoryIfNotExist(withPath: targetPath.path)
                if FileManager.default.fileExists(atPath: targetPath.path) == false {
                    var pathNew = "";
                    
                    do {
                        var substringArry = targetPath.path.components(separatedBy: "/");
                        substringArry.removeLast();
                        for var str in substringArry
                        {
                            str.append("/");
                            pathNew.append(str);
                            
                        }
                        
                        try FileManager.default.createDirectory(atPath: pathNew, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        LogError("Create directory at '\(targetPath.path)' failed: \(error)")
                        return false
                    }
                }
                let read = zipFile.readCurrentFileInZip()
                if Util.createFileIfNotExist(withPath: targetPath.path), let data = NSMutableData(length: Int(fileInfo.length)) {
                    do {
                        _ = try read.readData(withBuffer: data, error: ()) <= 0
                        
                        let fileHandle = try FileHandle(forWritingTo: toPath.appendingPathComponent(fileInfo.name))
                        fileHandle.write(data as Data)
                        fileHandle.closeFile()
                    } catch {
                        LogError("文件\(zipPath.path)解压失败: \(error)")
                        zipFile.close()
                        return false
                    }
                }
                

            } else { // 普通文件
                
                let read = zipFile.readCurrentFileInZip()
                if Util.createFileIfNotExist(withPath: targetPath.path), let data = NSMutableData(length: Int(fileInfo.length)) {
                    do {
                        _ = try read.readData(withBuffer: data, error: ()) <= 0
                        
                        let fileHandle = try FileHandle(forWritingTo: toPath.appendingPathComponent(fileInfo.name))
                        fileHandle.write(data as Data)
                        fileHandle.closeFile()
                    } catch {
                        LogError("文件\(zipPath.path)解压失败: \(error)")
                        zipFile.close()
                        return false
                    }
                }
 
            }
 
        } while zipFile.goToNextFileInZip()
        
        zipFile.close()
        return true
    }
    
    class func readCurrentFile( zipFile: OZZipFile ,targetPath:URL,fileInfo:OZFileInZipInfo,from zipPath: URL,toPath: URL){
        let read = zipFile.readCurrentFileInZip()
        if Util.createFileIfNotExist(withPath: targetPath.path), let data = NSMutableData(length: Int(fileInfo.length)) {
            do {
                _ = try read.readData(withBuffer: data, error: ()) <= 0
                
                let fileHandle = try FileHandle(forWritingTo: toPath.appendingPathComponent(fileInfo.name))
                fileHandle.write(data as Data)
                fileHandle.closeFile()
            } catch {
                LogError("文件\(zipPath.path)解压失败: \(error)")
                zipFile.close()
                return ;
            }
        }

        
    }
    /// 从资源包中读取json配置文件
    class func loadJsonObject(fromZip zipPath: URL) -> Any? {
        guard FileManager.default.fileExists(atPath: zipPath.path) else {
            LogWarning("\(zipPath.path) 资源包不存在")
            return nil
        }
        
        let zipFile = OZZipFile(fileName: zipPath.path, mode: .unzip)
        if zipFile.locateFile(inZip: Util.Constant.webappInfoFile) {
            let fileInfo = zipFile.getCurrentFileInZipInfo()
            let read = zipFile.readCurrentFileInZip()
            if let data = NSMutableData(length: Int(fileInfo.length)) {
                _ = read.readData(withBuffer: data)
                zipFile.close()
                do {
                    let json = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments)
                    return json
                } catch {
                    LogError("从资源包'\(zipPath.path)'读取配置文件失败: \(error)")
                    return nil
                }
            }
        } else {
            LogError("资源包'\(zipPath.path)'中没有’\(Util.Constant.webappInfoFile)‘文件")
        }
        
        return nil
    }
    
    /// 读取一个json配置文件
    class func loadJsonObject(fromUrl url: URL?) -> Any? {
        guard let url = url, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            return try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        } catch {
            LogError("Read json file error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - 其他
    
    /// url是否指向一个文件夹
    class func isFolder(url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                return true
            }
        }
        return false
    }
    
    /// 判断url是否指向一个zip文件
    class func isZip(url: URL) -> Bool {
        return url.isFileURL && url.lastPathComponent.hasSuffix(".zip")
    }
    
    /// 计算一个文件的md5
    class func fileMD5(_ path: URL) -> Data? {
        guard let fileHandle = try? FileHandle(forReadingFrom: path) else {
            return nil
        }
        
        let md5Ctx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: MemoryLayout<CC_MD5_CTX>.size)
        CC_MD5_Init(md5Ctx)
        
        // 分块读取避免内存占用过高
        while true {
            let data = fileHandle.readData(ofLength: 256)
            if data.count == 0 {
                break
            }
            
            _ = data.withUnsafeBytes({ (bytes: UnsafePointer<Int32>) -> Int32 in
                CC_MD5_Update(md5Ctx, bytes, CC_LONG(data.count))
            })
        }
        
        let digest = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Final(digest, md5Ctx)
        
        var hash = ""
        for i in 0..<CC_MD5_DIGEST_LENGTH {
            hash +=  String(format: "%02x", (digest[Int(i)]))
        }
        
        md5Ctx.deinitialize()
        digest.deinitialize()
        
        return hash.data(using: .utf8)
    }
}

internal extension URL {
    /// 获取相对路径，只对本地文件URL有效
    ///
    /// - Parameter baseUrl: 基准URL
    /// - Returns:           返回相对于baseUrl的url
    func relatedTo(_ baseUrl: URL?) -> URL? {
        guard let baseUrl = baseUrl else {
            return nil
        }
        
        let fullPath = self.path.replacingOccurrences(of: "//", with: "/")
        let basePath = baseUrl.path.replacingOccurrences(of: "//", with: "/")
        
        if basePath.endIndex >= fullPath.endIndex {
            return nil
        }
        
        let relatedPath = fullPath.substring(from: basePath.endIndex)
        return URL(fileURLWithPath: relatedPath)
    }
}

extension String {
    /// 获取字符串的md5值
    ///
    /// - Returns: 字符串的md5
    internal func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize()
        return (hash as String)
    }
}
