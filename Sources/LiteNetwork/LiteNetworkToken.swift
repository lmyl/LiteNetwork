//
//  LiteNetworkToken.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/4.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

protocol LiteNetworkTokenDelegate: class {
    /// 立马关闭当前会话
    func cancelSessionRightWay()
    
    /// 在完成当前task之后关闭对话
    func cancelSessionFinishCurrentTask()
}

final class LiteNetworkToken {
    
    private weak var delegate: LiteNetworkTokenDelegate?
    
    func cancelSessionRightWay() {
        guard let delegate = delegate else {
            return
        }
        delegate.cancelSessionRightWay()
        self.delegate = nil
    }
    
    func cancelSessionFinishCurrentTask() {
        guard let delegate = delegate else {
            return
        }
        delegate.cancelSessionFinishCurrentTask()
        self.delegate = nil
    }
    
    func setDelegate(delegate: LiteNetworkTokenDelegate) {
        self.delegate = delegate
    }

}
