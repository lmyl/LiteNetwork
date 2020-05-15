//
//  LiteNetworkStream.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

public final class LiteNetworkStream: NSObject {
    public typealias ProcessAuthenticationChallenge = (URLAuthenticationChallenge) -> (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?)
    public typealias DataCommunicateComplteteHandler = (Data?, Error?) -> ()
    public typealias WriteDataCompleteHandler = (Error?) -> ()
    public typealias ReadDataCompleteHandler = (Data?, Bool, Error?) -> ()
    public typealias StreamTaskCompleteHandler = (_ dueError: Bool, _ error: Error?) -> ()
    public typealias StreamCloseCompleteHandler = (_ dueError: Bool) -> ()
    
    private var liteNetworkStreamWorker = LiteNetworkStreamWorker()
    
}

public extension LiteNetworkStream {
    /// 更新session级别鉴权处理
    /// - Parameter authentication: 鉴权处理闭包，返回处理方法常量和认证证书
    func updateSessionAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateSessionAuthentication(for: authentication)
        return self
    }
    
    /// 更新task级别鉴权处理
    /// - Parameter authentication: 鉴权处理闭包，返回处理方法常量和认证证书
    func updateTaskAuthentication(for authentication: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateTaskAuthentication(for: authentication)
        return self
    }
    
    func updateStreamTaskComplete(for handler: @escaping StreamTaskCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamTaskComplete(for: handler)
        return self
    }
    
    /// 通过给定的域名和端口建立流任务
    /// - Parameters:
    ///   - host: 域名
    ///   - port: 端口
    func makeStreamWith(host: String, port: Int) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.makeStreamWith(host: host, port: port)
        return self
    }
    
    /// 通过给定的network Service建立流任务
    /// - Parameter netSever: network service
    func makeStreamWith(netSever: NetService) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.makeStreamWith(netSever: netSever)
        return self
    }
    
    /// 更新关闭读取流的操作
    /// - Parameter handler: 要进行的操作
    func updateStreamReadCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamReadCloseComplete(handler: handler)
        return self
    }
    
    /// 更新关闭写入流的操作
    /// - Parameter handler: 要进行的操作
    func updateStreamWriteCloseComplete(handler: @escaping StreamCloseCompleteHandler) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.updateStreamWriteCloseComplete(handler: handler)
        return self
    }
    
    /// 启用安全连接
    func startSecureConnect() -> LiteNetworkStreamToken {
        self.liteNetworkStreamWorker.startSecureConnect()
    }
    
    /// 开始连接
    func startConnect() -> LiteNetworkStreamToken {
        self.liteNetworkStreamWorker.startConnect()
    }
    
}


public extension LiteNetworkStream {
    /// 设置默认初始化配置
    func setDefaultConfigureType() -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setDefaultConfigureType()
        return self
    }
    
    /// 设置ephemeral初始化配置
    func setEphemeralConfigureType() -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setEphemeralConfigureType()
        return self
    }
    
    func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
    /// 设置资源请求的允许超时间隔
    /// - Parameter new: 目标时长
    func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setTimeoutIntervalForResource(for: new)
        return self
    }
    
    /// 设置等待其他数据时的允许超时间隔
    /// - Parameter new: 目标时长
    func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setTimeoutIntervalForRequest(for: new)
        return self
    }
    
    /// 设置是否请求应包含cookie存储中的cookie
    /// - Parameter new: bool
    func setHttpShouldSetCookies(for new: Bool) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setHttpShouldSetCookies(for: new)
        return self
    }
    
    func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setRequestCachePolicy(for: new)
        return self
    }
    
    func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        self.liteNetworkStreamWorker = self.liteNetworkStreamWorker.setHttpCookieAcceptPolicy(for: new)
        return self
    }
}




