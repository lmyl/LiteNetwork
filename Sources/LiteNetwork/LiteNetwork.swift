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
    /// Create a data request
    /// - Parameter request: a closure that return a `URLRequest`
     func makeDataRequest(for request: @escaping MakeDataRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeDataRequest(for: request)
        return self
    }
    
    /// Create a download requst
    /// - Parameter request: a closure that return a `URLRequest`
     func makeDownloadRequest(for request: @escaping MakeDownloadRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeDownloadRequest(for: request)
        return self
    }
    
    /// Create a new upload stream
    /// - Parameter request: a closure that return a `URLRequest`
     func makeNewUploadStream(for streamRequest: @escaping MakeUploadStreamRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeNewUploadStream(for: streamRequest)
        return self
    }
    
    /// Create a upload data request
     func makeUploadDataRequest(for request: @escaping MakeUploadDataRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeUploadDataRequest(for: request)
        return self
    }
    
    /// Create a upload file request
     func makeUploadFileRequest(for request: @escaping MakeUploadFileRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeUploadFileRequest(for: request)
        return self
    }
    
    /// Number of retries
     func retry(count: Int) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.retry(count: count)
        return self
    }
    
    /// Number of global retries
     func globeRetry(count: Int) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.globeRetry(count: count)
        return self
    }
    
    /// Handle task-specific authentication challenge
     func processTaskAuthenticationChallenge(for challenge: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processTaskAuthenticationChallenge(for: challenge)
        return self
    }
    
    /// Hanle session-wide authentication challenge
     func processSessionAuthenticationChallenge(for challenge: @escaping ProcessAuthenticationChallenge) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processSessionAuthenticationChallenge(for: challenge)
        return self
    }
    
    /// produce a new stream
     func produceNewStream(for new: @escaping ProduceNewStream) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.produceNewStream(for: new)
        return self
    }
    
    /// Create data handling method
    /// - Parameter data: `(URLResponse, Data?) -> ()`
    /// - Returns: `Self`
     func processData(for data: @escaping ProcessData) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processData(for: data)
        return self
    }
    
    /// Make redirect information
     func makeRedirect(for redirect: @escaping MakeRedirect) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeRedirect(for: redirect)
        return self
    }
    
    /// Make global redirect information
     func makeGlobeRedirect(for redirect: @escaping MakeRedirect) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.makeGlobeRedirect(for: redirect)
        return self
    }
    
    /// Make error handling method
     func processFailure(for failure: @escaping ProcessError) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processFailure(for: failure)
        return self
    }
    
    /// Make global error handling method
     func processGlobeFailure(for failure: @escaping ProcessError) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processGlobeFailure(for: failure)
        return self
    }
    
    /// Handle the progress of upload
     func processUploadProgress(for progress: @escaping ProcessProgress) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processUploadProgress(for: progress)
        return self
    }
    
    /// Handle the progress of download
     func processDownloadProgress(for progress: @escaping ProcessProgress) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processDownloadProgress(for: progress)
        return self
    }
    
    /// Handle the progress of download file
     func processDownloadFile(for processFile: @escaping ProcessDownloadFile) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processDownloadFile(for: processFile)
        return self
    }
    
    /// Handle `URLResponse`
     func processRequestSuccess(for processRequestSuccess: @escaping ProcessRequestSuccess) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.processRequestSuccess(for: processRequestSuccess)
        return self
    }
    
    /// Set the request analyzing method
     func analyzeRequest(for analyze: @escaping LiteNetwork.AnalyzeRequest) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.analyzeRequest(for: analyze)
        return self
    }
    
    
    @discardableResult
    /// trigger all the task
     func fire() -> LiteNetworkToken {
        self.liteNetworkWorker.fire()
    }
}

public extension LiteNetwork {
    
    /// Set the type of initial configuration to `Default`
    /// - Returns: `Self`
     func setDefaultConfigureType() -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setDefaultConfigureType()
        return self
    }
    
    /// Set the type of initial configuration to `Ephemeral`
     func setEphemeralConfigureType() -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setEphemeralConfigureType()
        return self
    }
    
    /// Append dictionary of other headers that send with request
     func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
    /// set `timeoutIntervalForRequest` attribute
     func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setTimeoutIntervalForResource(for: new)
        return self
    }
    
    /// set `timeoutIntervalForRequest` attribute
     func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setTimeoutIntervalForRequest(for: new)
        return self
    }
    
    /// Set whether requests should contain cookies from the cookie store
     func setHttpShouldSetCookies(for new: Bool) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setHttpShouldSetCookies(for: new)
        return self
    }
    
    /// Set the policy that determines when to return a response from the cache
     func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setRequestCachePolicy(for: new)
        return self
    }
    
    /// Set the policy that determines when cookies should be accepted
     func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        self.liteNetworkWorker = self.liteNetworkWorker.setHttpCookieAcceptPolicy(for: new)
        return self
    }
}
