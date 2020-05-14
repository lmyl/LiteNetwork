//
//  LiteNetworkSourceBag.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/2/27.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

struct LiteNetworkSourceBag {
    
    /// 创建数据任务请求
    var makeDataRequest: LiteNetwork.MakeDataRequest?
    
    /// 创建重定向
    var makeRedirect: LiteNetwork.MakeRedirect?
    
    /// 创建下载任务请求
    var makeDownloadRequest: LiteNetwork.MakeDownloadRequest?
    
    /// 创建上传流任务请求
    var makeUploadStreamRequest: LiteNetwork.MakeUploadStreamRequest?
    
    /// 处理数据
    var processData: [LiteNetwork.ProcessData] = []
    
    /// 处理错误
    var processError: LiteNetwork.ProcessError?
    
    /// 应答数据
    var responseData: Data?
    
    /// 获取taskID
    var requestTaskID: Int?
    
    /// task类型
    var taskType: LiteNetworkTask
    
    /// 资源包ID
    var sourceBagIdentifier: Int?
    
    /// 处理上传进程
    var processUploadProgress: LiteNetwork.ProcessProgress?
    
    /// 处理下载进程
    var processDownloadProgress: LiteNetwork.ProcessProgress?
    
    /// 处理下载文件
    var processDownloadFile: LiteNetwork.ProcessDownloadFile?
    
    /// 处理请求成功
    var processRequestSuccess: [LiteNetwork.ProcessRequestSuccess] = []
    
    /// 分析request指标
    var analyzeRequest: LiteNetwork.AnalyzeRequest?
    
    /// 创建新的流
    var makeNewStream: LiteNetwork.ProduceNewStream?
    
    /// 创建上传文件任务请求
    var makeUploadFileRequest: LiteNetwork.MakeUploadFileRequest?
    
    /// 创建上传数据任务请求
    var makeUploadDataRequest: LiteNetwork.MakeUploadDataRequest?
    
    /// 鉴权处理
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
