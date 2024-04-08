import DefferedTaskKit
import Dispatch
import Foundation
import SpryKit
import XCTest

final class DefferedTask_AsyncTests: XCTestCase {
    func test_async() async throws {
        var actual: [Int] = []

        actual = await DefferedTask<[Int?]>(result: [nil, 1, nil, 2, nil, 3, nil])
            .filterNils()
            .onComplete()
        XCTAssertEqual(actual, [1, 2, 3])

        actual = try await DefferedResult<[Int?], TestError>(success: {
            return [nil, 1, nil, 2, nil, 3, nil]
        })
        .filterNils()
        .onComplete()
        XCTAssertEqual(actual, [1, 2, 3])

        let actual2: Result<[Int], TestError> = await DefferedResult<[Int?], TestError>.success([nil, 3, nil, 2, nil, 1, nil])
            .filterNils()
            .onComplete()
        XCTAssertEqual(actual2, .success([3, 2, 1]))

        let actual3: Result<[Int], TestError2> = await DefferedResult<[Int?], TestError>.failure(.anyError1)
            .mapError { _ in
                return TestError2.anyError
            }
            .filterNils()
            .onComplete()
        XCTAssertEqual(actual3, .failure(.anyError))
    }
}
