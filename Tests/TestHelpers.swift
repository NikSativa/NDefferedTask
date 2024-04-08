import Foundation
import SpryKit

extension Result {
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let e):
            return e
        }
    }

    var value: Success? {
        switch self {
        case .success(let v):
            return v
        case .failure:
            return nil
        }
    }
}

enum TestError: Swift.Error, Equatable {
    case anyError1
    case anyError2
}

enum TestError2: Swift.Error, Equatable {
    case anyError
}
