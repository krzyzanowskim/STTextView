//
//  throttle.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Limits the frequency of executing a given operation to ensure it is not called more frequently than a specified duration.

 - Parameters:
   - duration: Foundation `Duration` type such as `.seconds(2.0)`. By default, .seconds(1.0)
   - identifier: (Optional) An identifier to distinguish between throttled operations. It is highly recommended to provide a custom identifier for clarity and to avoid potential issues with long call stack symbols. Use at your own risk with internal stack traces.
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - option: An option to customize the behavior of the throttle (default is `.default`).
   - operation: The operation to be executed when throttled.

 - Note:
   - The provided `identifier` is used to group related throttle operations. If multiple throttle calls share the same identifier, they will be considered as part of the same group, and the throttle behavior will apply collectively.
   - This method ensures that the operation is executed in a thread-safe manner within the specified actor context.

 - Usage:
    ```swift
    // Throttle a button tap action to prevent rapid execution.
    @IBAction func buttonTapped(_ sender: UIButton) {
        // Basic usage with default options
 
        throttle {
            print("Button tapped (throttled with default option)")
        }

        // Using custom identifiers to distinguish between throttled operations
 
        throttle(.seconds(3.0), identifier: "customIdentifier") {
            print("Custom throttled operation with identifier")
        }

        // Using 'ensureLast' option to guarantee that the last call is executed
 
        throttle(.seconds(3.0), identifier: "ensureLastExample", option: .ensureLast) {
            print("Throttled operation using ensureLast option")
        }
    }
   ```
 
 - See Also:
    - ThrottleOptions: Enum that defines various options for controlling throttle behavior.
 
 */

package func throttle(
    _ duration: TimeInterval = 1.0,
    identifier: String = "\(Thread.callStackSymbols)",
    by `actor`: ActorType = .mainActor,
    option: ThrottleOptions = .default,
    operation: @escaping () -> Void
) {
    Task {
        await throttler.throttle(
            duration,
            identifier: identifier,
            by: actor,
            option: option,
            operation: operation
        )
    }
}
