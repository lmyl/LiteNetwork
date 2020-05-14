//
//  LiteNetworkStreamChainSourceBag.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkStreamChainSourceBag {
    /// 链式资源包类型
    enum ChainSourceBagType {
        case Read
        case Write
        case Communicate
        case CloseWrite
        case CloseRead
    }
    
    let type: ChainSourceBagType
    var writeOperation: (input: Data, timout: TimeInterval, completeHandler: LiteNetworkStream.NormalCompleteHandler)?
    var readOperation: (min: Int, max: Int, timeout: TimeInterval, completeHandler: LiteNetworkStream.ReadDataCompleteHandler)?
    var communicateOperation: (input: Data, min: Int, max: Int, timeout: TimeInterval, completeHandler: LiteNetworkStream.DataCommunicateComplteteHandler)?
    
    /// 写入操作初始化
    /// - Parameters:
    ///   - writeData: 要写入的数据
    ///   - timeout: 允许超时间隔
    ///   - completeHandler: 完成回调
    init(writeData: Data, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.NormalCompleteHandler) {
        type = .Write
        writeOperation = (writeData, timeout, completeHandler)
    }
    
    /// 读取操作初始化
    /// - Parameters:
    ///   - readMinLength: 读取数据的最短长度
    ///   - maxLength: 读取数据的最大长度
    ///   - timeout: 允许超时间隔
    ///   - completeHandler: 完成回调
    init(readMinLength: Int, maxLength: Int, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
        type = .Read
        readOperation = (readMinLength, maxLength, timeout, completeHandler)
    }
    
    /// 会话操作初始化
    /// - Parameters:
    ///   - communicateData: 要进行会话的数据
    ///   - minLength: 读取的最小长度
    ///   - maxLength: 读取的最大长度
    ///   - timeout: 允许超时间隔
    ///   - completeHandler: 完成回调
    init(communicateData: Data, minLength: Int, maxLength: Int, timeout: TimeInterval, completeHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        type = .Communicate
        communicateOperation = (communicateData, minLength, maxLength, timeout, completeHandler)
    }
    
    private init(type: ChainSourceBagType) {
        self.type = type
    }
    
    static var closeReadSourceBag: LiteNetworkStreamChainSourceBag {
        LiteNetworkStreamChainSourceBag(type: .CloseRead)
    }
    
    static var closeWriteSourceBag: LiteNetworkStreamChainSourceBag {
        LiteNetworkStreamChainSourceBag(type: .CloseWrite)
    }
}
