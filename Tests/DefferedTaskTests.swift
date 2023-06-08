import Dispatch
import Foundation
import NDefferedTask
import NSpry
import XCTest

final class DefferedTaskTests: XCTestCase {
    private enum Value: Equatable, SpryEquatable {
        case idle
        case timedOut
        case correct
    }

    func test_regular_behavior() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        var subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
        } onDeinit: {
            stopped += 1
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
        }
        .set(userInfo: "subject")

        var intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }
        intSubject.set(userInfo: "intSubject")
            .onComplete {
                completed2.append($0)
            }

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 0)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])

        subject = nil

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 0)

        intSubject = nil

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 1)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])
    }

    func test_irregular_behavior() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        var subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
        } onDeinit: {
            stopped += 1
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
        }
        .set(userInfo: "subject")

        var intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }.set(userInfo: "intSubject")

        intSubject.onComplete {
            completed2.append($0)
        }

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 0)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])

        // rm sub task first
        intSubject = nil

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 0)

        subject = nil

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 1)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])
    }

    func test_twice_onComplete() {
        let intSubject: DefferedTask<Int> = .init(execute: { _ in
            // shoulde never end
        })

        intSubject.onComplete { _ in
            assertionFailure("should never heppen")
        }

        XCTAssertThrowsAssertion {
            intSubject.onComplete { _ in
                assertionFailure("should never heppen")
            }
        }
    }

    func test_init() {
        var actual: Int?
        let subject: DefferedTask<Int> = .init(result: 1)
        subject.onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, 1)

        let subject2: DefferedTask<Int> = .init(result: {
            return 2
        })
        subject2.onComplete { result in
            actual = result
        }
        XCTAssertEqual(actual, 2)
    }

    func test_oneWay() {
        var actual: Bool = false
        DefferedTask<Int>(execute: { completion in
            completion(1)
        }, onDeinit: {
            actual = true
        }).oneWay()
        XCTAssertTrue(actual)
    }

    func test_afterComplete() {
        let createSubject: () -> DefferedTask<Int> = {
            let intSubject: DefferedTask<Int> = .init(execute: { _ in
                // shoulde never end
            })
            .weakify()
            .weakify()
            .strongify()
            .strongify()
            .set(completionQueue: .absent)
            .set(workQueue: .absent)

            intSubject.onComplete { _ in
                assertionFailure("should never heppen")
            }
            return intSubject
        }

        XCTAssertThrowsAssertion {
            createSubject().onComplete { _ in
                assertionFailure("should never heppen")
            }
        }

        XCTAssertThrowsAssertion {
            var some: AnyObject?
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            var some: AnyObject = NSObject()
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            var some: Any?
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            var some: Any = NSObject()
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            var some: DefferedTask<Int>?
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            var some: DefferedTask<Int> = .init(result: 1)
            _ = createSubject().assign(to: &some)
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().weakify()
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().strongify()
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().set(workQueue: .absent)
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().set(completionQueue: .absent)
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().set(userInfo: "some")
        }
    }

    func test_unwrap() {
        var actual: Int?

        DefferedTask<Int?>(result: nil)
            .unwrap(with: 1)
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, 1)

        DefferedTask<Int?>(result: nil)
            .unwrap {
                return 2
            }
            .onComplete { result in
                actual = result
            }
        XCTAssertEqual(actual, 2)
    }
}
