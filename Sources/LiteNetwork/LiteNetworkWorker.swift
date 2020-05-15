//
//  LiteNetworkWorker.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/26.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

 final class LiteNetworkWorker: NSObject {
    
    private var makeRequestSemaphore = DispatchSemaphore(value: 0)
    
    private let makeRequestSerialQueue = DispatchQueue(label: "LiteNetwork.makeRequest.token.com")
    
    private let sessionTaskDelegateQueue: OperationQueue
    
    private var sourceBagsManager = LiteNetworkSourceBagManager()
    private var configureManager = LiteNetworkConfigureManager()
    
    private lazy var session = { () -> URLSession in
        let newConfiguration = self.configureManager.getNewSessionConfigure()
        return URLSession(configuration: newConfiguration, delegate: self, delegateQueue: self.sessionTaskDelegateQueue)
    }()
    
    private var sessionToken = LiteNetworkToken()
    
    private let cancelFlagRWQueue = DispatchQueue(label: "LiteNetwork.rwCancel.token.com", attributes: .concurrent)
    
    private var isCancel: Bool {
        get {
            var result = false
            self.cancelFlagRWQueue.sync {
                [unowned self] in
                result = self.underlayIsCancel
            }
            return result
        }
        set(newValue) {
            self.cancelFlagRWQueue.async(flags: .barrier, execute: {
                [unowned self] in
                self.underlayIsCancel = newValue
            })
        }
    }
    
    private var underlayIsCancel = false
    
     override init() {
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1 //设置并行操作数为1
        self.sessionTaskDelegateQueue = opQueue
        
        super.init()
        
        self.sessionToken.setDelegate(delegate: self)
        
    }
}

extension LiteNetworkWorker: URLSessionDelegate {
    /// 在需要处理session级别的身份请求认证时被调用
    /// - Parameters:
    ///   - session: 包含需要进行身份请求的task的session
    ///   - challenge: 包含身份请求验证的对象
    ///   - completionHandler: 调用的处理方式
     func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let handlerBlock = sourceBagsManager.sessionAuthenticationChallenge else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let handler = handlerBlock(challenge)
        completionHandler(handler.disposition, handler.credential)
    }
}

extension LiteNetworkWorker: URLSessionTaskDelegate {
    /// 在需要处理task级别的身份请求认证时被调用
    /// - Parameters:
    ///   - session: 包含需要进行身份请求验证task的session
    ///   - task: 需要进行身份请求验证的task
    ///   - challenge: 包含身份请求验证的对象
    ///   - completionHandler: 调用的处理方式
     func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID), let newAuthenticationChallenge = sourceBag.processAuthenticationChallenge else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let handler = newAuthenticationChallenge(challenge)
        completionHandler(handler.disposition, handler.credential)
    }
    
    ///在task完成数据传输之后被调用
    /// - Parameters:
    ///   - session: 包含完成数据传输task的session
    ///   - task: 完成数据传输的task
    ///   - error: 如果在传输过程中发生error，返回error；否则为NULL
     func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var isRetry = false
        
        defer {
            if sourceBagsManager.isEmpty() {
                session.invalidateAndCancel()
                self.makeRequestSemaphore.signal()
            } else {
                if !isRetry {
                    self.makeRequestSemaphore.signal()
                }
            }
        }
        
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return
        }
        if let error = error {
            isRetry = isRetryWhenErrorFor(taskID: taskID, error: error)
            return
        } else {
            switch sourceBag.taskType {
            case .Data:
                if let httpResponse = task.response {
                    let data = sourceBag.responseData
                    for processData in sourceBag.processData {
                        processData(httpResponse, data)
                    }
                    for processRequestSuccess in sourceBag.processRequestSuccess {
                        processRequestSuccess(httpResponse)
                    }
                } else {
                    isRetry = isRetryWhenErrorFor(taskID: taskID, error: LiteNetworkError.NoResponse)
                    return
                }
            default:
                if let httpResponse = task.response {
                    for processRequestSuccess in sourceBag.processRequestSuccess {
                        processRequestSuccess(httpResponse)
                    }
                } else {
                    isRetry = isRetryWhenErrorFor(taskID: taskID, error: LiteNetworkError.NoResponse)
                    return
                }
            }
            
            sourceBagsManager.removeSourceBag(for: taskID)
        }
    }
    
    /// 告知远程服务器需要http重定向（只有在default会话和ephemeral会话中才会被调用，background会话自动追随重定向。
    /// - Parameters:
    ///   - session: 包含导致重定向task的session
    ///   - task: 请求导致重定向的task
    ///   - response: 服务器对原始请求的相应对象
    ///   - request: 包含新地址的URL请求对象
    ///   - completionHandler: 回调处理
     func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let taskID = task.taskIdentifier
        guard let redirect = sourceBagsManager.getRedirectForSourceBag(for: taskID) else {
            completionHandler(nil)
            return
        }
        let newRequest = redirect(response, request)
        completionHandler(newRequest)
    }
    
    /// 上传文件定期调用，提供上传进度
    /// - Parameters:
    ///   - session: 包含data task的session
    ///   - task: data task
    ///   - bytesSent: 自上次调用方法以来发送的字节数
    ///   - totalBytesSent: 到现在为止上传的字节数
    ///   - totalBytesExpectedToSend: 总共要发送的字节数
     func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return
        }
        guard let processProgress = sourceBag.processUploadProgress else {
            return
        }
        processProgress(totalBytesSent, totalBytesExpectedToSend)
    }
    
    /// 已完成task指标收集
    /// - Parameters:
    ///   - session: 包含符合条件task的session
    ///   - task: 被收集指标的task
    ///   - metrics: 封装了 session  task的指标
     func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return
        }
        guard let analyzeRequest = sourceBag.analyzeRequest else {
            return
        }
        analyzeRequest(metrics)
    }
    
    /// 当task需要向服务器发送新的请求体时被调用
    /// - Parameters:
    ///   - session: 包含符合条件task的session
    ///   - task: 需要新的请求体的task
    ///   - completionHandler: 回调处理
     func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            completionHandler(nil)
            return
        }
        guard let makeNewStream = sourceBag.makeNewStream else {
            completionHandler(nil)
            return
        }
        let newStream = makeNewStream()
        completionHandler(newStream)
    }
    
}

extension LiteNetworkWorker:  URLSessionDataDelegate {
    /// 收到部分预期数据
    /// - Parameters:
    ///   - session: 包含符合条件task的session
    ///   - dataTask:提供数据的data task
    ///   - data: 包含已传输数据的数据对象
     func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskID = dataTask.taskIdentifier
        sourceBagsManager.appendDataForSourceBag(for: taskID, data: data)
    }
    
    /// 收到服务器的初始回复之后调用，或支持复杂的 multipart / x-mixed-replace 内容类型
    /// - Parameters:
    ///   - session: 包含符合条件task的session
    ///   - dataTask: 收到初始化回复的data task
    ///   - response: 包含了header的URL response
    ///   - completionHandler: 回调处理
     func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}

extension LiteNetworkWorker: URLSessionDownloadDelegate {
    /// 已完成下载任务
    /// - Parameters:
    ///   - session: 包含符合条件task的session
    ///   - downloadTask: 完成的下载任务
    ///   - location: 临时存储文件的URL
     func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let taskID = downloadTask.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return
        }
        guard let processFile = sourceBag.processDownloadFile else {
            return
        }
        processFile(location)
    }
    
    /// 下载文件定期调用，提供下载进度
    /// - Parameters:
    ///   - session: 包含download task的session
    ///   - downloadTask: download task
    ///   - bytesWritten: 自上次调用以来传输的字节数
    ///   - totalBytesWritten: 总共传输的字节数
    ///   - totalBytesExpectedToWrite: 预期传输的总字节数
     func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskID = downloadTask.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return
        }
        guard let processProgress = sourceBag.processDownloadProgress else {
            return
        }
        processProgress(totalBytesWritten, totalBytesExpectedToWrite)
    }
}

extension LiteNetworkWorker {
    /// 创建数据请求
    /// - Parameter request: 返回URLRequest的闭包
    func makeDataRequest(for request: @escaping LiteNetwork.MakeDataRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeDataRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    ///创建下载请求
    func makeDownloadRequest(for request: @escaping LiteNetwork.MakeDownloadRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeDownloadRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    ///创建新的上传流
    func makeNewUploadStream(for streamRequest: @escaping LiteNetwork.MakeUploadStreamRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadStreamRequest: streamRequest)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// 创建上传数据请求
    func makeUploadDataRequest(for request: @escaping LiteNetwork.MakeUploadDataRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadDataRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// 创建上传文件请求
    func makeUploadFileRequest(for request: @escaping LiteNetwork.MakeUploadFileRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadFileRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// 重试次数
     func retry(count: Int) -> Self {
        sourceBagsManager.updateRequestRetryCountToTrail(for: count)
        return self
    }
    
    /// 全局重试次数
     func globeRetry(count: Int) -> Self {
        sourceBagsManager.updateGlobeRequestRetryCount(for: count)
        return self
    }
    
    /// task级别的鉴权处理
    /// - Parameter challenge: 身份验证
    func processTaskAuthenticationChallenge(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) -> Self {
        sourceBagsManager.updateProcessAuthenticationChallengeToTrail(for: challenge)
        return self
    }
    
    /// session级别的鉴权处理
    /// - Parameter challenge: 身份验证
    func processSessionAuthenticationChallenge(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) -> Self {
        sourceBagsManager.updateSessionProcessAuthenticationChallengeToTrail(for: challenge)
        return self
    }
    
    func produceNewStream(for new: @escaping LiteNetwork.ProduceNewStream) -> Self {
        sourceBagsManager.updateProduceNewStreamToTrail(for: new)
        return self
    }
    
    func processData(for data: @escaping LiteNetwork.ProcessData) -> Self {
        sourceBagsManager.appendDataProcessToTrail(new: data)
        return self
    }
    
    
    func makeRedirect(for redirect: @escaping LiteNetwork.MakeRedirect) -> Self {
        sourceBagsManager.updateRedirectToTrail(for: redirect)
        return self
    }
    
    func makeGlobeRedirect(for redirect: @escaping LiteNetwork.MakeRedirect) -> Self {
        sourceBagsManager.updateGlobeRedirect(for: redirect)
        return self
    }
    
    func processFailure(for failure: @escaping LiteNetwork.ProcessError) -> Self {
        sourceBagsManager.updateProcessFailureToTrail(new: failure)
        return self
    }
    
    func processGlobeFailure(for failure: @escaping LiteNetwork.ProcessError) -> Self {
        sourceBagsManager.updateGlobeProcessFailureToTrail(new: failure)
        return self
    }
    
    func processUploadProgress(for progress: @escaping LiteNetwork.ProcessProgress) -> Self {
        sourceBagsManager.updateUploadProcessProgressToTrail(new: progress)
        return self
    }
    
    func processDownloadProgress(for progress: @escaping LiteNetwork.ProcessProgress) -> Self {
        sourceBagsManager.updateDownloadProcessProgressToTrail(new: progress)
        return self
    }
    
    func processDownloadFile(for processFile: @escaping LiteNetwork.ProcessDownloadFile) -> Self {
        sourceBagsManager.updateDownloadFileToTrail(new: processFile)
        return self
    }
    
    func processRequestSuccess(for processRequestSuccess: @escaping LiteNetwork.ProcessRequestSuccess) -> Self {
        sourceBagsManager.appendProcessRequestSuccessToTrail(new: processRequestSuccess)
        return self
    }
    
     func analyzeRequest(for analyze: @escaping LiteNetwork.AnalyzeRequest) -> Self {
        sourceBagsManager.updateAnalyzeRequestToTrail(for: analyze)
        return self
    }
    
    
    @discardableResult
     func fire() -> LiteNetworkToken {
        let _ = self.session
        for sourceBag in sourceBagsManager.readSourceBags() {
            self.makeRequestSerialQueue.async {
                [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.makeRequestSemaphore.wait()
                strongSelf.fireSourceBag(sourceBag: sourceBag)
            }
        }
        
        self.makeRequestSemaphore.signal()
        return sessionToken
    }
    
    /// 触发资源包task
    /// - Parameter sourceBag: 资源包实例
    private func fireSourceBag(sourceBag: LiteNetworkSourceBag) {
        guard let identifier = sourceBag.sourceBagIdentifier else {
            return
        }
        switch sourceBag.taskType {
        case .Data:
            guard let makeRequest = sourceBag.makeDataRequest else {
                self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                self.makeRequestSemaphore.signal()
                return
            }
            let newRequest = makeRequest()
            let task = self.session.dataTask(with: newRequest)
            var newSourceBag = sourceBag
            newSourceBag.requestTaskID = task.taskIdentifier
            self.sourceBagsManager.setSourceBag(new: newSourceBag, sourceBagIdentifier: identifier)
            task.resume()
        case .Download:
            guard let makeRequest = sourceBag.makeDownloadRequest else {
                self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                self.makeRequestSemaphore.signal()
                return
            }
            let newRequest = makeRequest()
            let task = self.session.downloadTask(with: newRequest)
            var newSourceBag = sourceBag
            newSourceBag.requestTaskID = task.taskIdentifier
            self.sourceBagsManager.setSourceBag(new: newSourceBag, sourceBagIdentifier: identifier)
            task.resume()
        case .UploadStream:
            if let makeUploadStreamRequest = sourceBag.makeUploadStreamRequest {
                let newRequest = makeUploadStreamRequest()
                if newRequest.httpBodyStream == nil, sourceBag.makeNewStream == nil {
                    self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                    self.makeRequestSemaphore.signal()
                    return
                } else {
                    let task = self.session.uploadTask(withStreamedRequest: newRequest)
                    var newSourceBag = sourceBag
                    newSourceBag.requestTaskID = task.taskIdentifier
                    self.sourceBagsManager.setSourceBag(new: newSourceBag, sourceBagIdentifier: identifier)
                    task.resume()
                }
            } else {
                self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                self.makeRequestSemaphore.signal()
                return
            }
        case .UploadData:
            guard let makeUploadDataRequest = sourceBag.makeUploadDataRequest else {
                self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                self.makeRequestSemaphore.signal()
                return
            }
            let newUploadDataRequest = makeUploadDataRequest()
            let task = self.session.uploadTask(with: newUploadDataRequest.request, from: newUploadDataRequest.data)
            var newSourceBag = sourceBag
            newSourceBag.requestTaskID = task.taskIdentifier
            self.sourceBagsManager.setSourceBag(new: newSourceBag, sourceBagIdentifier: identifier)
            task.resume()
        case .UploadFile:
            guard let makeUploadFileRequest = sourceBag.makeUploadFileRequest else {
                self.sourceBagsManager.removeSourceBagForIdentifier(id: identifier)
                self.makeRequestSemaphore.signal()
                return
            }
            let newUploadFileRequest = makeUploadFileRequest()
            let task = self.session.uploadTask(with: newUploadFileRequest.request, fromFile: newUploadFileRequest.path)
            var newSourceBag = sourceBag
            newSourceBag.requestTaskID = task.taskIdentifier
            self.sourceBagsManager.setSourceBag(new: newSourceBag, sourceBagIdentifier: identifier)
            task.resume()
        }
    }
    
    /// 在指定资源包task触发发生错误时尝试重新触发
    /// - Parameters:
    ///   - taskID: 指定taskID
    ///   - error: 产生的错误
    private func isRetryWhenErrorFor(taskID: Int, error: Error) -> Bool {
        var isRetry = false
        guard var sourceBag = sourceBagsManager.getSourceBag(for: taskID) else {
            return false
        }
        let retryCount = sourceBagsManager.getRetryCountForSourceBag(for: taskID)
        if retryCount > 0 && !self.isCancel {
            sourceBag.responseData = nil
            sourceBag.retryCount = retryCount - 1
            isRetry = true
            fireSourceBag(sourceBag: sourceBag)
        } else {
            if let processError = sourceBagsManager.getProcessErrorForSourceBag(for: taskID) {
                processError(error)
            }
            sourceBagsManager.removeAllSourceBag()
        }
        return isRetry
    }
}

extension LiteNetworkWorker {
     func setDefaultConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Default)
        return self
    }
    
     func setEphemeralConfigureType() -> Self {
        configureManager.updateConfigureType(type: .Ephemeral)
        return self
    }
    
     func appendHttpAdditionalHeaders(dictionary: [AnyHashable: Any]) -> Self {
        configureManager.appendHttpAdditionalHeaders(dictionary: dictionary)
        return self
    }
    
     func setTimeoutIntervalForResource(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForRequest(for: new)
        return self
    }
    
     func setTimeoutIntervalForRequest(for new: TimeInterval) -> Self {
        configureManager.updateTimeoutIntervalForRequest(for: new)
        return self
    }
    
     func setHttpShouldSetCookies(for new: Bool) -> Self {
        configureManager.updateHttpShouldSetCookies(for: new)
        return self
    }
    
     func setRequestCachePolicy(for new: NSURLRequest.CachePolicy) -> Self {
        configureManager.updateRequestCachePolicy(for: new)
        return self
    }
    
     func setHttpCookieAcceptPolicy(for new: HTTPCookie.AcceptPolicy) -> Self {
        configureManager.updateHttpCookieAcceptPolicy(for: new)
        return self
    }
}

extension LiteNetworkWorker: LiteNetworkTokenDelegate {
    func cancelSessionRightWay() {
        self.sourceBagsManager.removeAllSourceBag()
        self.isCancel = true
        self.session.invalidateAndCancel()
    }
    
    func cancelSessionFinishCurrentTask() {
        self.sourceBagsManager.removeAllSourceBag()
        self.isCancel = true
        self.session.finishTasksAndInvalidate()
    }
}
