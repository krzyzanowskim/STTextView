//
//  delay.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Delays the execution of a provided operation by a specified time duration.

 - Parameters:
   - duration: Foundation `Duration` type such sa .seconds(2.0). By default, .seconds(1.0)
   - actorType: The actor type on which the operation should be executed (default is `.main`).
   - operation: The operation to be executed after the delay.
 
 - Note:
   - The provided `identifier` is used to group related debounce operations. If multiple debounce calls share the same identifier, they will be considered as part of the same group, and the debounce behavior will apply collectively.
   - This method ensures that the operation is executed in a thread-safe manner within the specified actor context.

 - Usage:
    ```swift
    // Delay execution by 2 seconds using a custom duration.
    delay(.seconds(2)) {
        print("Delayed operation")
    }
    
    // Alternatively, delay execution by 1.5 seconds using the .seconds convenience method.
    delay(.seconds(1.5)) {
        print("Another delayed operation")
    }
    ```
 */

package func delay(
    _ duration: TimeInterval = 1.0,
    by `actor`: ActorType = .mainActor,
    operation: @escaping () -> Void
) {
    Task {
        await throttler.delay(
            duration,
            by: actor,
            operation: operation
        )
    }
}
