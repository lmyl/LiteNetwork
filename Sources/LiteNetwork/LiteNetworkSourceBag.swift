//
//  LiteNetworkSourceBag.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/27.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

struct LiteNetworkSourceBag {
    
    /// Create a data request
    var makeDataRequest: LiteNetwork.MakeDataRequest?
    
    /// Create redirect
    var makeRedirect: LiteNetwork.MakeRedirect?
    
    /// Create a download request
    var makeDownloadRequest: LiteNetwork.MakeDownloadRequest?
    
    /// Create a upload stream request
    var makeUploadStreamRequest: LiteNetwork.MakeUploadStreamRequest?
    
    /// Data handing methods
    var processData: [LiteNetwork.ProcessData] = []
    
    /// Error handling methods
    var processError: LiteNetwork.ProcessError?
    
    /// Response data of type `Data`
    var responseData: Data?
    
    /// `Int` ID of the request task
    var requestTaskID: Int?
    
    /// the type of task
    var taskType: LiteNetworkTask
    
    /// `Int` ID of the sourdeBag
    var sourceBagIdentifier: Int?
    
    /// Handle the progress of upload
    var processUploadProgress: LiteNetwork.ProcessProgress?
    
    /// Handle the progress of download
    var processDownloadProgress: LiteNetwork.ProcessProgress?
    
    /// Handle the download file
    var processDownloadFile: LiteNetwork.ProcessDownloadFile?
    
    /// Handle `URLResponse`
    var processRequestSuccess: [LiteNetwork.ProcessRequestSuccess] = []
    
    /// Analyse `URLSessionTaskMetrics` of request
    var analyzeRequest: LiteNetwork.AnalyzeRequest?
    
    /// Create new stream
    var makeNewStream: LiteNetwork.ProduceNewStream?
    
    /// Create upload file request
    var makeUploadFileRequest: LiteNetwork.MakeUploadFileRequest?
    
    /// Create upload data request
    var makeUploadDataRequest: LiteNetwork.MakeUploadDataRequest?
    
    /// Handle authentication challenge
    var processAuthenticationChallenge: LiteNetwork.ProcessAuthenticationChallenge?
    
    var retryCount: Int?
    
    init(makeDataRequest: @escaping LiteNetwork.MakeDataRequest) {
        self.makeDataRequest = makeDataRequest
        self.taskType = .Data
    }
    
    init(makeDownloadRequest: @escaping LiteNetwork.MakeDataRequest) {
        self.makeDownloadRequest = makeDownloadRequest
        self.taskType = .Download
    }
    
    init(makeUploadStreamRequest: @escaping LiteNetwork.MakeUploadStreamRequest) {
        self.makeUploadStreamRequest = makeUploadStreamRequest
        self.taskType = .UploadStream
    }
    
    init(makeUploadDataRequest: @escaping LiteNetwork.MakeUploadDataRequest) {
        self.makeUploadDataRequest = makeUploadDataRequest
        self.taskType = .UploadData
    }
    
    init(makeUploadFileRequest: @escaping LiteNetwork.MakeUploadFileRequest) {
        self.makeUploadFileRequest = makeUploadFileRequest
        self.taskType = .UploadFile
    }
    
}
