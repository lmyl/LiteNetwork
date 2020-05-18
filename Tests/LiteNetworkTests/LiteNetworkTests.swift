import XCTest
@testable import LiteNetwork

final class LiteNetworkTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let expection = expectation(description: #function)
        LiteNetwork().makeDataRequest(for: {
            URLRequest(url: URL(string: "https://www.baidu.com")!)
            }).setRequestCachePolicy(for: .reloadIgnoringCacheData).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }).makeDataRequest(for: {
            return URLRequest(url: URL(string: "https://www.apple.com/cn/")!)
            }).setRequestCachePolicy(for: .reloadIgnoringCacheData).processData(for: {
                response, dataOrNil in
                if let data = dataOrNil, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
                expection.fulfill()
            }).processGlobeFailure(for: {
                print("Error:" + $0.localizedDescription)
                expection.fulfill()
            }).fire()
        
        
        
        waitForExpectations(timeout: 10) { errorOrNil in
            if let error = errorOrNil {
                print("Error:" + error.localizedDescription)
            } else {
                print("TestCompleted")
            }
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
