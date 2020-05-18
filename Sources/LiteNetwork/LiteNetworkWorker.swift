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
        opQueue.maxConcurrentOperationCount = 1 
        self.sessionTaskDelegateQueue = opQueue
        
        super.init()
        
        self.sessionToken.setDelegate(delegate: self)
        
    }
}

extension LiteNetworkWorker: URLSessionDelegate {
    /// Event called when handle task-specific authentication challenges
    /// - Parameters:
    ///   - session: The session containing the task that requested authentication.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
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
    /// Event called when handle task-level authentication challenges.
    /// - Parameters:
    ///   - session: The session containing the task that requested authentication.
    ///   - task: task that requested authentication
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
     func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let taskID = task.taskIdentifier
        guard let sourceBag = sourceBagsManager.getSourceBag(for: taskID), let newAuthenticationChallenge = sourceBag.processAuthenticationChallenge else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let handler = newAuthenticationChallenge(challenge)
        completionHandler(handler.disposition, handler.credential)
    }
    
    /// Event called when task finished transferring data.
    /// - Parameters:
    ///   - session: The session containing the task whose request finished transferring data.
    ///   - task: The task whose request finished transferring data.
    ///   - error: If an error occurred, an error object indicating how the transfer failed, otherwise NULL.
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
    
    /// Tells the delegate that the remote server requested an HTTP redirect.
    /// - Parameters:
    ///   - session: The session containing the task whose request resulted in a redirect.
    ///   - task: The task whose request resulted in a redirect.
    ///   - response: An object containing the server’s response to the original request.
    ///   - request: A URL request object filled out with the new location.
    ///   - completionHandler: A block that your handler should call with either the value of the request parameter, a modified URL request object, or NULL to refuse the redirect and return the body of the redirect response.
     func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let taskID = task.taskIdentifier
        guard let redirect = sourceBagsManager.getRedirectForSourceBag(for: taskID) else {
            completionHandler(nil)
            return
        }
        let newRequest = redirect(response, request)
        completionHandler(newRequest)
    }
    
    /// Periodically informs the delegate of the progress of sending body content to the server.
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
    
    /// Tells the delegate that the session finished collecting metrics for the task.
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
    
    /// Tells the delegate when a task requires a new request body stream to send to the remote server.
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
    
    /// Tells the delegate that the data task has received some of the expected data.
     func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskID = dataTask.taskIdentifier
        sourceBagsManager.appendDataForSourceBag(for: taskID, data: data)
    }
    
    /// Tells the delegate that the data task received the initial reply (headers) from the server.
     func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
}

extension LiteNetworkWorker: URLSessionDownloadDelegate {
    
    /// Tells the delegate that a download task has finished downloading.
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
    
    /// Periodically informs the delegate about the download’s progress.
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
    /// Create a data request
    /// - Parameter request: A closure that return a `URLRequest`
    func makeDataRequest(for request: @escaping LiteNetwork.MakeDataRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeDataRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// Create a download request
    func makeDownloadRequest(for request: @escaping LiteNetwork.MakeDownloadRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeDownloadRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// create a new upload stream
    func makeNewUploadStream(for streamRequest: @escaping LiteNetwork.MakeUploadStreamRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadStreamRequest: streamRequest)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// Create a upload data request
    func makeUploadDataRequest(for request: @escaping LiteNetwork.MakeUploadDataRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadDataRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// Create a upload file request
    func makeUploadFileRequest(for request: @escaping LiteNetwork.MakeUploadFileRequest) -> Self {
        let sourceBag = LiteNetworkSourceBag(makeUploadFileRequest: request)
        sourceBagsManager.push(new: sourceBag)
        return self
    }
    
    /// Allowed retry times
     func retry(count: Int) -> Self {
        sourceBagsManager.updateRequestRetryCountToTrail(for: count)
        return self
    }
    
    /// Allowed gloabal retry times
     func globeRetry(count: Int) -> Self {
        sourceBagsManager.updateGlobeRequestRetryCount(for: count)
        return self
    }
    
    /// Handle authentication challenge in task-specific
    func processTaskAuthenticationChallenge(for challenge: @escaping LiteNetwork.ProcessAuthenticationChallenge) -> Self {
        sourceBagsManager.updateProcessAuthenticationChallengeToTrail(for: challenge)
        return self
    }
    
    /// Handle authentication challenge in session-wide
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
    
    /// trigger task in sourceBag
    /// - Parameter sourceBag: instance of `LiteNetworkSourceBag`
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
    
    /// Try to re-trugger when error occur in the specified task ID  resourceBag task trigger
    /// - Parameters:
    ///   - taskID: specified task ID
    ///   - error: occurred error
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
