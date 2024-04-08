import DefferedTaskKit
import Dispatch
import Foundation
import SpryKit
import XCTest

final class DefferedTask_ArrayTests: XCTestCase {
    func test_filterNils() {
        var actual: [Int] = []

        DefferedTask<[Int?]>(result: [nil, 1, nil, 2, nil, 3, nil])
            .filterNils()
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, [1, 2, 3])

        DefferedResult<[Int?], TestError>(success: [nil, 3, nil, 2, nil, 1, nil])
            .filterNils()
            .onComplete { result in
                actual = try! result.get()
            }
        XCTAssertEqual(actual, [3, 2, 1])
    }
}
