import Dispatch
import Foundation
import NDefferedTask
import NSpry
import XCTest

final class DefferedTask_VoidTests: XCTestCase {
    func test_init() {
        let exp = expectation(description: "wait")
        DefferedTask<Void>().onComplete {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_success() {
        let exp = expectation(description: "wait")
        DefferedTask<Void>.success()
            .onComplete {
                exp.fulfill()
            }
        wait(for: [exp], timeout: 1)
    }

    func test_success_result() {
        let exp = expectation(description: "wait")
        DefferedResult<Void, TestError>.success()
            .onComplete {
                exp.fulfill()
            }
        wait(for: [exp], timeout: 1)
    }

    func test_mapVoid() {
        let exp = expectation(description: "wait")
        let subject: DefferedResult<Void, TestError> = DefferedResult<Int, TestError>.success(1)
            .mapVoid()
        subject.onComplete {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_flatMapVoid() {
        let exp = expectation(description: "wait")
        let subject: DefferedTask<Void> = DefferedResult<Int, TestError>.success(1)
            .flatMapVoid()
        subject.onComplete {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}
