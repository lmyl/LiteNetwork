//
//  LiteNetwork.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/26.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

 public final class LiteNetwork {
    
    public typealias MakeDataRequest = () -> URLRequest
    public typealias MakeDownloadRequest = () -> URLRequest
    public typealias MakeUploadStreamRequest = () -> URLRequest
    public typealias MakeRedirect = (HTTPURLResponse, URLRequest) -> URLRequest?
    public typealias ProcessData = (URLResponse, Data?) -> ()
    public typealias ProcessError = (Error) -> ()
    public typealias ProcessProgress = (_ now: Int64, _ total: Int64) -> ()
    public typealias ProcessDownloadFile = (URL) -> ()
    public typealias ProcessRequestSuccess = (URLResponse) -> ()
    public typealias AnalyzeRequest = (URLSessionTaskMetrics) -> ()
    public typealias ProduceNewStream = () -> InputStream?
    public typealias MakeUploadFileRequest = () -> (request: URLRequest, path: URL)
    public typealias MakeUploadDataRequest = () -> (request: URLRequest, data: Data)
    public typealias ProcessAuthenticationChallenge = (URLAuthenticationChallenge) -> (disposition: URLSession.AuthChallengeDisposition, credential: URLCredential?)
    
    private var liteNetworkWorker = LiteNetworkWorker()
    
}

public extension LiteNetwork {
    /// 创建数据请求
    /// - Parameter request: 返回URLRequest的闭包
     func makeDataRequest(for request: @escaping MakeDataRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeDataRequest(for: request)
        return self
    }
    
    ///创建下载请求
     func makeDownloadRequest(for request: @escaping MakeDownloadRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeDownloadRequest(for: request)
        return self
    }
    
    ///创建新的上传流
     func makeNewUploadStream(for streamRequest: @escaping MakeUploadStreamRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeNewUploadStream(for: streamRequest)
        return self
    }
    
    /// 创建上传数据请求
     func makeUploadDataRequest(for request: @escaping MakeUploadDataRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeUploadDataRequest(for: request)
        return self
    }
    
    /// 创建上传文件请求
     func makeUploadFileRequest(for request: @escaping MakeUploadFileRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeUploadFileRequest(for: request)
        return self
    }
    
    /// 重试次数
     func retry(count: Int) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.retry(count: count)
        return self
    }
    
    /// 全局重试次数
     func globeRetry(count: Int) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.globeRetry(count: count)
        return self
    }
    
    /// task级别的鉴权处理
    /// - Parameter challenge: 身份验证
     func processTaskAuthenticationChallenge(for challenge: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processTaskAuthenticationChallenge(for: challenge)
        return self
    }
    
    /// session级别的鉴权处理
    /// - Parameter challenge: 身份验证
     func processSessionAuthenticationChallenge(for challenge: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processSessionAuthenticationChallenge(for: challenge)
        return self
    }
    
     func produceNewStream(for new: @escaping ProduceNewStream) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.produceNewStream(for: new)
        return self
    }
    
     func processData(for data: @escaping ProcessData) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processData(for: data)
        return self
    }
    
    
     func makeRedirect(for redirect: @escaping MakeRedirect) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeRedirect(for: redirect)
        return self
    }
    
     func makeGlobeRedirect(for redirect: @escaping MakeRedirect) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeGlobeRedirect(for: redirect)
        return self
    }
    
     func processFailure(for failure: @escaping ProcessError) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processFailure(for: failure)
        return self
    }
    
     func processGlobeFailure(for failure: @escaping ProcessError) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processGlobeFailure(for: failure)
        return self
    }
    
     func processUploadProgress(for progress: @escaping ProcessProgress) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processUploadProgress(for: progress)
        return self
    }
    
     func processDownloadProgress(for progress: @escaping ProcessProgress) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processDownloadProgress(for: progress)
        return self
    }
    
     func processDownloadFile(for processFile: @escaping ProcessDownloadFile) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processDownloadFile(for: processFile)
        return self
    }
    
     func processRequestSuccess(for processRequestSuccess: @escaping ProcessRequestSuccess) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processRequestSuccess(for: processRequestSuccess)
        return self
    }
    
     func analyzeRequest(for analyze: @escaping LiteNetwork.AnalyzeRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.analyzeRequest(for: analyze)
        return self
    }
    
    
    @discardableResult
     func fire() -> LiteNetworkToken {
        self.liteNetworkWorker.fire()
    }
}

public extension LiteNetwork {
     func setDefaultConfigureType() -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setDefaultConfigureType()
        return self
    }
    
     func setEphemeralConfigureType() -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setEphemeralConfigureType()
        return self
    }
    
     func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
     func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setTimeoutIntervalForResource(for: new)
        return self
    }
    
     func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setTimeoutIntervalForRequest(for: new)
        return self
    }
    
     func setHttpShouldSetCookies(for new: Bool) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setHttpShouldSetCookies(for: new)
        return self
    }
    
     func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setRequestCachePolicy(for: new)
        return self
    }
    
     func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setHttpCookieAcceptPolicy(for: new)
        return self
    }
}
