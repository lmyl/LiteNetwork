//
//  LiteNetworkError.swift
//  PocketCampus
//
//  Created by 刘洋 on 2020/3/10.
//  Copyright © 2020 刘洋. All rights reserved.
//

import Foundation

public enum LiteNetworkError: Error {
    case NoResponse
    case NoResponseData
    case NoDataReadFormStream
}


extension LiteNetworkError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .NoResponse:
            return "没有响应体"
        case .NoResponseData:
            return "没有响应数据"
        case .NoDataReadFormStream:
            return "从流中读不到数据"
        }
    }
}

extension LiteNetworkError: LocalizedError {
    public var localizedDescription: String {
        self.description
    }
}
