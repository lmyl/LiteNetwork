//
//  LiteNetworkStreamToken.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

protocol LiteNetworkStreamTokenDelegate: LiteNetworkTokenDelegate {
    /// 与服务器的简单通信
       /// - Parameters:
       ///   - input: 要写入的数据
       ///   - minLength: 传输的最短长度
       ///   - maxLength: 传输的最长长度
       ///   - timeout: 允许超时间隔
       ///   - completionHandler: 完成回调
    func simpleCommunicateWithSever(input: Data, minLength: Int, maxLength: Int, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler)
    
    /// 写入数据
    /// - Parameters:
    ///   - input: 要写入的数据
    ///   - timeout: 允许超时间隔
    ///   - completionHandler: 完成处理
    func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler)
    
    /// 读取数据
    /// - Parameters:
    ///   - minLength: 最短读取长度
    ///   - maxLength: 最大读取长度
    ///   - timeout: 允许超时间隔
    ///   - completeHandler: 完成回调
    func readData(minLength: Int, maxLength: Int, timeout: TimeInterval?, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler)
    
    /// 关闭写入流
    func closeWriteStream()
    
    /// 关闭读取流
    func closeReadStream()
}

final class LiteNetworkStreamToken {
    private weak var delegate: LiteNetworkStreamTokenDelegate?
    
    func setDelegate(delegate: LiteNetworkStreamTokenDelegate) {
        self.delegate = delegate
    }
    
    func simpleCommunicateWithSever(input: Data, minLength: Int = 1, maxLength: Int = 2048, timeout: TimeInterval? = nil, completionHandler: @escaping LiteNetworkStream.DataCommunicateComplteteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.simpleCommunicateWithSever(input: input, minLength: minLength, maxLength: maxLength, timeout: timeout, completionHandler: completionHandler)
    }
    
    func writeData(input: Data, timeout: TimeInterval?, completionHandler: @escaping LiteNetworkStream.WriteDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.writeData(input: input, timeout: timeout, completionHandler: completionHandler)
    }
    
    func readData(minLength: Int, maxLength: Int, timeout: TimeInterval?, completeHandler: @escaping LiteNetworkStream.ReadDataCompleteHandler) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.readData(minLength: minLength, maxLength: maxLength, timeout: timeout, completeHandler: completeHandler)
    }
    
    func closeWriteStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeWriteStream()
    }
    
    func closeReadStream() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.closeReadStream()
    }
    
    func cancelSessionFinishCurrentTask() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionFinishCurrentTask()
    }
    
    func cancelSessionRightWay() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.cancelSessionRightWay()
    }
}
