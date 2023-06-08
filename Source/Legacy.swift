import Foundation

@available(iOS, deprecated, renamed: "DefferedTask")
@available(macOS, deprecated, renamed: "DefferedTask")
public typealias Callback<T> = DefferedTask<T>

@available(iOS, deprecated, renamed: "DefferedResult")
@available(macOS, deprecated, renamed: "DefferedResult")
public typealias ResultCallback<T, E: Error> = DefferedResult<T, E>

@available(iOS, deprecated, renamed: "PendingTask")
@available(macOS, deprecated, renamed: "PendingTask")
public typealias PendingCallback<T> = PendingTask<T>

@available(iOS, deprecated, renamed: "PendingResult")
@available(macOS, deprecated, renamed: "PendingResult")
public typealias PendingResultCallback<T, E: Error> = PendingResult<T, E>

@available(iOS, deprecated, renamed: "PollingTask")
@available(macOS, deprecated, renamed: "PollingTask")
public typealias PollingCallback<T> = PollingTask<T>
