import Dispatch
import Foundation
import NDefferedTask
import NSpry
import XCTest

final class DefferedTask_combineTests: XCTestCase {
    func test_combine_list() {
        var actual: [Int]!
        DefferedTask.combine(DefferedTask<Int>(result: 1), DefferedTask<Int>(result: 2), DefferedTask<Int>(result: 3))
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, [1, 2, 3])
    }

    func test_combine_array() {
        var actual: [Int]!
        let tasks: [DefferedTask<Int>] = [
            .init(result: 1),
            .init(result: 2),
            .init(result: 3)
        ]
        DefferedTask.combine(tasks)
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, [1, 2, 3])
    }

    func test_combine_array2() {
        var actual: [Int]!
        let tasks: [DefferedTask<Int>] = [
            .init(result: 1),
            .init(result: 2),
            .init(result: 3)
        ]
        tasks.combine()
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, [1, 2, 3])
    }

    func test_combine_empty_array() {
        var actual: [Int]!
        let tasks: [DefferedTask<Int>] = []
        DefferedTask.combine(tasks)
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, [])
    }

    func test_combineSuccess() {
        var actual: (lhs: Int, rhs: String)!
        DefferedResult<Int, TestError>.success(1)
            .combineSuccess(with: .success("2"))
            .recover(with: (2, "3"))
            .onComplete { result in
                actual = result
            }
        XCTAssertEqualAny(actual, (1, "2"))
    }

    func test_combineError() {
        var actual: (lhs: Int, rhs: String)!
        DefferedResult<Int, TestError>.success(1)
            .combineSuccess(with: .failure(.anyError1))
            .recover(with: (2, "3"))
            .onComplete { result in
                actual = result
            }
        XCTAssertEqualAny(actual, (2, "3"))
    }
}
