import DefferedTaskKit
import Dispatch
import Foundation
import SpryKit
import XCTest

final class DefferedTask_ResultTests: XCTestCase {
    func test_alternative_completion() {
        var actual: Result<[Int], TestError>!

        DefferedResult<[Int?], TestError>(success: [nil, 1, nil, 2, nil, 3, nil])
            .filterNils()
            .on(success: { result in
                actual = .success(result)
            }) { _ in
                fatalError("should never happen")
            }
        XCTAssertEqual(actual, .success([1, 2, 3]))

        DefferedResult<[Int?], TestError>(failure: .anyError1)
            .filterNils()
            .on(success: { _ in
                fatalError("should never happen")
            }) { error in
                actual = .failure(error)
            }
        XCTAssertEqual(actual, .failure(.anyError1))
    }

    func test_compactMap() {
        var actual: Result<[Int], TestError>!

        DefferedResult<[Int?], TestError>(success: {
            return [nil, 1, nil, 2, nil, 3, nil]
        })
        .compactMap {
            return $0
        }
        .on(success: { result in
            actual = .success(result)
        }) { _ in
            fatalError("should never happen")
        }
        XCTAssertEqual(actual, .success([1, 2, 3]))
    }

    func test_tryMap() {
        var actual: Result<[Int], TestError>!

        DefferedResult<[Int?], TestError>(success: {
            return [nil, 1, nil, 2, nil, 3, nil]
        })
        .tryMap { _ -> [Int] in
            throw TestError2.anyError
        }
        .mapError { _ -> TestError in
            return .anyError1
        }
        .on(success: { result in
            actual = .success(result)
        }) { error in
            actual = .failure(error)
        }
        XCTAssertEqual(actual, .failure(.anyError1))

        actual = nil
        DefferedResult<[Int?], TestError>(failure: {
            return .anyError1
        })
        .tryMap { _ -> [Int] in
            fatalError("should never happen")
        }
        .mapError { _ -> TestError in
            return .anyError1
        }
        .on(success: { result in
            actual = .success(result)
        }) { error in
            actual = .failure(error)
        }
        XCTAssertEqual(actual, .failure(.anyError1))
    }

    func test_before_after() {
        var actual: Result<[Int], TestError>!
        var actualBefore: Result<[Int], TestError>!
        var actualAfter: Result<[Int], TestError>!

        DefferedResult<[Int], TestError>(success: {
            return [1, 2, 3]
        })
        .beforeSuccess { result in
            XCTAssertNil(actual)
            actualBefore = .success(result)
        }
        .beforeFail { _ in
            fatalError("should never happen")
        }
        .afterSuccess { result in
            XCTAssertNotNil(actual)
            actualAfter = .success(result)
        }
        .afterFail { _ in
            fatalError("should never happen")
        }
        .on(success: { result in
            actual = .success(result)
        }) { error in
            actual = .failure(error)
        }
        XCTAssertEqual(actualBefore, .success([1, 2, 3]))
        XCTAssertEqual(actual, .success([1, 2, 3]))
        XCTAssertEqual(actualAfter, .success([1, 2, 3]))

        actual = nil
        DefferedResult<[Int?], TestError>(failure: {
            return .anyError1
        })
        .tryMap { _ -> [Int] in
            fatalError("should never happen")
        }
        .mapError { _ -> TestError in
            return .anyError1
        }
        .beforeSuccess { _ in
            fatalError("should never happen")
        }
        .beforeFail { error in
            XCTAssertNil(actual)
            actualBefore = .failure(error)
        }
        .afterSuccess { _ in
            fatalError("should never happen")
        }
        .afterFail { error in
            XCTAssertNotNil(actual)
            actualAfter = .failure(error)
        }
        .on(success: { result in
            actual = .success(result)
        }) { error in
            actual = .failure(error)
        }

        XCTAssertEqual(actualBefore, .failure(.anyError1))
        XCTAssertEqual(actual, .failure(.anyError1))
        XCTAssertEqual(actualAfter, .failure(.anyError1))
    }

    func test_recover_error() {
        var actual: [Int]!
        DefferedResult<[Int], TestError>(failure: {
            return .anyError1
        })
        .recover(with: [1, 2, 3])
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [1, 2, 3])

        DefferedResult<[Int], TestError>(failure: {
            return .anyError1
        })
        .recover {
            return [3, 2, 1]
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [3, 2, 1])

        DefferedResult<[Int], TestError>(failure: {
            return .anyError1
        })
        .recover { _ in
            return [1, 2, 3]
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [1, 2, 3])
    }

    func test_recover_result() {
        var actual: [Int]!
        DefferedResult<[Int], TestError>(success: {
            return [1, 2, 3]
        })
        .recover(with: [])
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [1, 2, 3])

        DefferedResult<[Int], TestError>(success: {
            return [3, 2, 1]
        })
        .recover {
            fatalError("should never happen")
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [3, 2, 1])

        DefferedResult<[Int], TestError>(success: {
            return [1, 2, 3]
        })
        .recover { _ in
            fatalError("should never happen")
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [1, 2, 3])
    }

    func test_nilIfFailure() {
        var actual: [Int]? = []
        DefferedResult<[Int], TestError>(failure: {
            return .anyError1
        })
        .nilIfFailure()
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, nil)

        DefferedResult<[Int], TestError>(success: {
            return [1, 2]
        })
        .nilIfFailure()
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, [1, 2])
    }

    func test_unwrap_with_value() {
        var actual: Result<[Int], TestError>!
        DefferedResult<[Int]?, TestError>(failure: {
            return .anyError1
        })
        .unwrap(with: [2, 1])
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .failure(.anyError1))

        DefferedResult<[Int]?, TestError>(success: {
            return [1, 2]
        })
        .unwrap(with: [2, 1])
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .success([1, 2]))

        DefferedResult<[Int]?, TestError>(success: {
            return nil
        })
        .unwrap(with: [2, 1])
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .success([2, 1]))
    }

    func test_unwrap_with_closure() {
        var actual: Result<[Int], TestError>!
        DefferedResult<[Int]?, TestError>(failure: {
            return .anyError1
        })
        .unwrap {
            return [2, 1]
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .failure(.anyError1))

        DefferedResult<[Int]?, TestError>(success: {
            return [1, 2]
        })
        .unwrap {
            return [2, 1]
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .success([1, 2]))

        DefferedResult<[Int]?, TestError>(success: {
            return nil
        })
        .unwrap {
            return [2, 1]
        }
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .success([2, 1]))
    }

    func test_unwrap_with_error() {
        var actual: Result<[Int], TestError>!
        DefferedResult<[Int]?, TestError>(failure: {
            return .anyError1
        })
        .unwrap(orThrow: .anyError2)
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .failure(.anyError1))

        DefferedResult<[Int]?, TestError>(success: {
            return [1, 2]
        })
        .unwrap(orThrow: .anyError2)
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .success([1, 2]))

        DefferedResult<[Int]?, TestError>(success: {
            return nil
        })
        .unwrap(orThrow: .anyError2)
        .onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, .failure(.anyError2))
    }
}
