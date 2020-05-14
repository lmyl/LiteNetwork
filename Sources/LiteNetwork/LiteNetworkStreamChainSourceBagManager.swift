//
//  LiteNetworkStreamChainSourceBagManager.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

final class LiteNetworkStreamChainSourceBagManager {
    private var sourceBags: [LiteNetworkStreamChainSourceBag] = []
    
    private var rwQueue = DispatchQueue(label: "LiteNetworkStreamChainSourceBagManager.token.com", attributes: .concurrent)
}

extension LiteNetworkStreamChainSourceBagManager {
    /// 读取链式资源包数组
    func readSourceBags() -> [LiteNetworkStreamChainSourceBag] {
        var sourceBags: [LiteNetworkStreamChainSourceBag] = []
        rwQueue.sync {
            [unowned self] in
            sourceBags =  self.sourceBags
        }
        return sourceBags
    }
    
    /// 写入链式资源包数组
    /// - Parameter sourceBags: 链式资源包数组
    func writeSourceBags(sourceBags: [LiteNetworkStreamChainSourceBag]) {
        rwQueue.async(flags: .barrier, execute: {
            [unowned self] in
            self.sourceBags = sourceBags
        })
    }
    
    /// 判断链式资源包数组是否为空
    func isEmpty() -> Bool {
        readSourceBags().count == 0
    }
    
    /// 添加资源包
    /// - Parameter sourceBag: 要添加的流数据链式资源包
    func append(sourceBag: LiteNetworkStreamChainSourceBag) {
        var sourceBags = readSourceBags()
        sourceBags.append(sourceBag)
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// 移除第一个链式资源包
    func removeFirst() {
        var sourceBags = readSourceBags()
        if sourceBags.isEmpty {
            return
        }
        sourceBags.removeFirst()
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// 移除当前所有链式资源包
    func removeAll() {
        let sourceBags: [LiteNetworkStreamChainSourceBag] = []
        writeSourceBags(sourceBags: sourceBags)
    }
    
    /// 获取第一个链式资源包
    func firstSourceBag() -> LiteNetworkStreamChainSourceBag? {
        let sourceBags = readSourceBags()
        if sourceBags.isEmpty {
            return nil
        }
        return sourceBags.first
    }
}
