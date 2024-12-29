//
//  Throttler.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-09-08.
//

import Foundation

/// Options for debouncing an operation.
package enum DebounceOptions {
    /// The default debounce behavior.
    case `default`
    /// Run the operation immediately and debounce subsequent calls.
    case runFirst
}

/// Options for throttling an operation.
package enum ThrottleOptions {
    /// The default throttle behavior.
    case `default`
    /// Guarantee that the last call is executed even if it's after the throttle time.
    case ensureLast
}

package enum ActorType {
    case currentActor
    case mainActor
    
    @Sendable func run(_ operation: () -> Void) async {
        self == .mainActor ? await MainActor.run { operation() } : operation()
    }
}

/// a global actor variable for free functions (delay, debounce, throttle) to rely on. (internal use only)
let throttler = Throttler()

/// An actor for managing debouncing, throttling and delay operations designed to be the internal use.
actor Throttler {
    private lazy var cachedTask: [String: Task<(), Never>] = [:]
    private lazy var lastAttemptDate: [String: Date] = [:]
    
    /// Debounces an operation, ensuring it's executed only after a specified time interval
    /// has passed since the last call.
    ///
    /// - Parameters:
    ///   - duration: The time interval for debouncing.
    ///   - identifier: A custom identifier for distinguishing debounce tasks. It's recommended
    ///                 to use your own identifier for better control, but you can use the default
    ///                 which is based on the call stack symbols (use at your own risk).
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - option: The debounce option (default or runFirstImmediately).
    ///   - operation: The operation to debounce.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func debounce(
        _ duration: TimeInterval = 1.0,
        identifier: String = "\(Thread.callStackSymbols)",
        by `actor`: ActorType = .mainActor,
        option: DebounceOptions = .default,
        operation: @escaping () -> Void
    ) async {
        switch option {
        case .runFirst:
            if cachedTask[identifier] == nil {
                Task { await actor.run(operation) }
            }
            fallthrough
        default:
            cachedTask[identifier]?.cancel()
            cachedTask[identifier] = {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                    guard !Task.isCancelled else { return }
                    await actor.run(operation)
                }
            }()
        }
    }

    /// Throttles an operation, ensuring it's executed at most once within a specified time interval.
    ///
    /// - Parameters:
    ///   - duration: The time interval for throttling.
    ///   - identifier: A custom identifier for distinguishing throttle tasks. It's recommended
    ///                 to use your own identifier for better control, but you can use the default
    ///                 which is based on the call stack symbols (use at your own risk).
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - option: The throttle option (default or runFirstImmediately).
    ///   - operation: The operation to throttle.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func throttle(
        _ duration: TimeInterval = 1.0,
        identifier: String = "\(Thread.callStackSymbols)",
        by actor: ActorType = .mainActor,
        option: ThrottleOptions = .default,
        operation: @escaping () -> Void
    ) async {
        let lastDate = lastAttemptDate[identifier]
        let lastTimeInterval = Date().timeIntervalSince(lastDate ?? .distantPast)

        let throttleRun = {
            guard lastTimeInterval > duration else { return }
            
            self.lastAttemptDate[identifier] = Date()

            try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }
            await actor.run(operation)
            
            self.lastAttemptDate[identifier] = nil
        }

        switch option {
        case .ensureLast:
            await debounce(duration, identifier: identifier, by: actor, operation: operation)
            await throttleRun()
        default:
            await throttleRun()
        }
    }

    /// Delays the execution of an operation by a specified time interval.
    ///
    /// - Parameters:
    ///   - duration: The time interval to delay execution.
    ///   - actorType: The actor type on which to execute the operation (default is main actor).
    ///   - operation: The operation to delay.
    ///
    /// - Note: This method ensures that the operation is executed in a thread-safe manner
    ///         within the specified actor context.
    
    func delay(
        _ duration: TimeInterval = 1.0,
        by `actor`: ActorType = .mainActor,
        operation: @escaping () -> Void
    ) async {
        try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
        await actor.run(operation)
    }
}

