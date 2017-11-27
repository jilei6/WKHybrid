//
//  ValidationChecker.swift
//  Hybrid
//
//  Created by jilei on 2017/5/17.
//  Copyright © 2017年 jilei. All rights reserved.
//

import UIKit

internal class ValidationChecker {
    
    /// 校验资源包是否被篡改
    ///
    /// - Parameters:
    ///   - path:        资源包的位置
    ///   - encrypedMD5: 资源包信息中加密的MD5值
    ///   - key:         AES加密所用的Key
    /// - Returns:       校验成功返回true，失败返回false
    class func validateFile(_ path: URL, with encrypedMD5: String, using key: String) -> Bool {
        guard let fileMD5 = Util.fileMD5(path) else {
            LogError("计算文件MD5值失败")
            return false
        }
        guard let decodedEncrypedMD5 = NSData(base64Encoded: encrypedMD5, options: .ignoreUnknownCharacters) else {
            LogError("Base64 Decode失败")
            return false
        }
        
        // 解密得到的MD5和文件的MD5对比
        if let decryptedMD5 = TripleDESDecrypt(decodedEncrypedMD5 as Data, key: key), fileMD5 == decryptedMD5 {
            return true
        }
        
        return false
    }
    
    /// 3DES解密
    ///
    /// - Parameters:
    ///   - data:  密文
    ///   - key:   秘钥
    /// - Returns: 解密后的明文
    private class func TripleDESDecrypt(_ data: Data, key: String) -> Data? {
        guard let keyData = key.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        
        let keyBytes = keyData.withUnsafeBytes { (bytes) -> UnsafePointer<UInt8> in
            return bytes
        }
        let dataBytes = data.withUnsafeBytes { (bytes) -> UnsafePointer<UInt8> in
            return bytes
        }
        
        var bufferData = Data(count: data.count + kCCBlockSize3DES)
        let bufferPtr = bufferData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> in
            return bytes
        }
        var bytesDecrypted = Int(0)
        
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithm3DES),
                             CCOptions(kCCOptionECBMode),
                             keyBytes,
                             kCCKeySize3DES,
                             nil,
                             dataBytes,
                             data.count,
                             bufferPtr,
                             bufferData.count,
                             &bytesDecrypted)
        
        if Int32(status) == Int32(kCCSuccess) {
            bufferData.count = bytesDecrypted
            return bufferData
        } else {
            return nil
        }
    }
}
