import DefferedTaskKit
import Dispatch
import Foundation
import SpryKit
import Threading
import XCTest

final class DefferedTaskTests: XCTestCase {
    private static let timeout: TimeInterval = 0.2

    private enum Value: Equatable, SpryEquatable {
        case idle
        case timedOut
        case correct
    }

    func test_strongify_both_on_same_thread() {
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

    func test_strongify_both_on_other_threads() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        let expSubject = expectation(description: "subject")
        let deinitSubject = expectation(description: "deinitSubject")
        var subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
            expSubject.fulfill()
        } onDeinit: {
            stopped += 1
            deinitSubject.fulfill()
        }
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))
        .flatMap { v in
            return v
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
        }
        .set(userInfo: "subject")

        let expIntSubject = expectation(description: "subject2")
        var intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }
        .set(userInfo: "intSubject")
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))

        intSubject.onComplete {
            completed2.append($0)
            expIntSubject.fulfill()
        }

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 0)
        wait(for: [expSubject, expIntSubject], timeout: Self.timeout)

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
        wait(for: [deinitSubject], timeout: Self.timeout)

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 1)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])
    }

    func test_behavior_unretaned_both_tasks() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        let expSubject = expectation(description: "subject")
        expSubject.isInverted = true
        var subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
        } onDeinit: {
            stopped += 1
        }
        .weakify()
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))
        .flatMap { v in
            return v
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
            expSubject.fulfill()
        }
        .set(userInfo: "subject")

        let expIntSubject = expectation(description: "intSubject")
        expIntSubject.isInverted = true
        var intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }
        .set(userInfo: "intSubject")
        .weakify()

        intSubject.onComplete {
            completed2.append($0)
            expIntSubject.fulfill()
        }

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 0)

        // rm sub task first
        intSubject = nil
        subject = nil

        wait(for: [expSubject, expIntSubject], timeout: Self.timeout)

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 1)

        XCTAssertEqual(beforeCompleted, [])
        XCTAssertEqual(completed2, [])
        XCTAssertEqual(deferredCompleted, [])
    }

    func test_behavior_unretained_subject() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        let expSubject = expectation(description: "subject")
        var subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
        } onDeinit: {
            stopped += 1
        }
        .weakify()
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))
        .flatMap { v in
            return v
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
            expSubject.fulfill()
        }
        .set(userInfo: "subject")

        let expIntSubject = expectation(description: "intSubject")
        let intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }
        .set(userInfo: "intSubject")
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))

        intSubject.onComplete {
            completed2.append($0)
            expIntSubject.fulfill()
        }

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 0)

        // rm sub task first
        subject = nil

        wait(for: [expSubject, expIntSubject], timeout: Self.timeout)

        XCTAssertEqual(started, 1)
        XCTAssertEqual(stopped, 0)

        XCTAssertEqual(beforeCompleted, [.correct])
        XCTAssertEqual(completed2, [1])
        XCTAssertEqual(deferredCompleted, [.correct])
    }

    func test_behavior_unretaned_subtask() {
        var started = 0
        var stopped = 0

        var beforeCompleted: [Value] = []
        var completed2: [Int] = []
        var deferredCompleted: [Value] = []

        let expSubject = expectation(description: "subject")
        expSubject.isInverted = true
        let subject: DefferedTask<Value>! = .init { completion in
            started += 1
            completion(.correct)
        } onDeinit: {
            stopped += 1
        }
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))
        .flatMap { v in
            return v
        }
        .beforeComplete { result in
            beforeCompleted.append(result)
        }
        .afterComplete { result in
            deferredCompleted.append(result)
            expSubject.fulfill()
        }
        .set(userInfo: "subject")

        let expIntSubject = expectation(description: "intSubject")
        expIntSubject.isInverted = true
        var intSubject: DefferedTask<Int>! = subject.flatMap { _ in
            return 1
        }
        .set(userInfo: "intSubject")
        .weakify()
        .set(workQueue: .async(Queue.background))
        .set(completionQueue: .async(Queue.background))

        intSubject.onComplete {
            completed2.append($0)
            expIntSubject.fulfill()
        }

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 0)

        // rm sub task first
        intSubject = nil

        wait(for: [expSubject, expIntSubject], timeout: Self.timeout)

        XCTAssertEqual(started, 0)
        XCTAssertEqual(stopped, 0)

        XCTAssertEqual(beforeCompleted, [])
        XCTAssertEqual(completed2, [])
        XCTAssertEqual(deferredCompleted, [])
    }

    func test_twice_onComplete() {
        let intSubject: DefferedTask<Int> = .init(execute: { _ in
            // shoulde never end
        })

        intSubject.onComplete { _ in
            assertionFailure("should never heppen")
        }

        #if (os(macOS) || os(iOS) || os(visionOS)) && (arch(x86_64) || arch(arm64))
        XCTAssertThrowsAssertion {
            intSubject.onComplete { _ in
                assertionFailure("should never heppen")
            }
        }
        #endif
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

    #if (os(macOS) || os(iOS) || os(visionOS)) && (arch(x86_64) || arch(arm64))
    func test_assertions() {
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
            _ = createSubject().flatMap { _ in
                return "str"
            }.flatMapVoid()
        }

        XCTAssertThrowsAssertion {
            _ = createSubject().compactMap { _ in
                return "str"
            }.flatMapVoid()
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
    #endif

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

    func test_queue() {
        var actual: Int = -1
        var isBackgroundThreadMap: Bool = false
        var isMainThreadComplete: Bool = false

        let expMap = expectation(description: "map")
        let expComplete = expectation(description: "complete")
        DefferedTask<Int>(result: 0)
            .set(workQueue: .async(Queue.background))
            .set(completionQueue: .async(Queue.main))
            .map { _ in
                isBackgroundThreadMap = !Thread.isMainThread
                expMap.fulfill()
                return 1
            }
            .onComplete { result in
                isMainThreadComplete = Thread.isMainThread
                actual = result
                expComplete.fulfill()
            }
        wait(for: [expMap, expComplete], timeout: Self.timeout)

        XCTAssertEqual(actual, 1)
        XCTAssertTrue(isBackgroundThreadMap)
        XCTAssertTrue(isMainThreadComplete)
    }

    func test_queue2() {
        var actual: Int = -1
        var isBackgroundThreadMap: Bool = false
        var isBackgroundThreadComplete: Bool = false

        let expMap = expectation(description: "map")
        let expComplete = expectation(description: "complete")
        DefferedTask<Int?>(result: nil)
            .set(workQueue: .async(Queue.background))
            .set(completionQueue: .async(Queue.background))
            .compactMap { _ in
                isBackgroundThreadMap = !Thread.isMainThread
                expMap.fulfill()
                return 1
            }
            .onComplete { result in
                isBackgroundThreadComplete = !Thread.isMainThread
                actual = result
                expComplete.fulfill()
            }
        wait(for: [expMap, expComplete], timeout: Self.timeout)

        XCTAssertEqual(actual, 1)
        XCTAssertTrue(isBackgroundThreadMap)
        XCTAssertTrue(isBackgroundThreadComplete)
    }
}
