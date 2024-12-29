//
//  debounce.swift
//  Throttler
//
//  Created by seoksoon jang on 2023-04-03.
//

import Foundation

/**
 Debounce Function

 - Parameters:
   - duration: Foundation `Duration` type such as `.seconds(2.0)`. Default is .seconds(1.0)
   - identifier: A unique identifier for this debounce operation. By default, it uses the call stack symbols as the identifier. You can provide a custom identifier to group related debounce operations. It is highly recommended to use your own identifier to avoid unexpected behavior, but you can use the internal stack trace identifier at your own risk.
   - actorType: The actor context in which to run the operation. Use `.main` to run the operation on the main actor or `.current` for the current actor context.
   - option: The debounce option to control the behavior of the debounce operation. You can choose between `.default` and `.runFirst`. The default behavior delays the operation execution by the specified duration, while `runFirst` executes the operation immediately and applies debounce to subsequent calls.
   - operation: The operation to debounce. This is a closure that contains the code to be executed when the debounce conditions are met.

 - Note:
   - The provided `identifier` is used to group related debounce operations. If multiple debounce calls share the same identifier, they will be considered as part of the same group, and the debounce behavior will apply collectively.
   - This method ensures that the operation is executed in a thread-safe manner within the specified actor context.

 - Example:
   ```swift
   // Debounce a button tap action to prevent rapid execution.
   @IBAction func buttonTapped(_ sender: UIButton) {
       // Basic debounce with default options
 
       debounce {
           print("Button tapped (debounced with default option)")
       }

       // Using custom identifiers
 
       debounce(.seconds(1.0), identifier: "customIdentifier") {
           print("Custom debounced operation with identifier")
       }
       
       // Using 'runFirst' option to execute the first operation immediately and debounce the rest
 
       debounce(.seconds(1.0), identifier: "runFirstExample", option: .runFirst) {
           print("Debounced operation using runFirst option")
       }
   }
   ```

 - See Also:
    - DebounceOptions: Enum that defines various options for controlling debounce behavior.
*/

package func debounce(
    _ duration: TimeInterval = 1.0,
    identifier: String = "\(Thread.callStackSymbols)",
    by `actor`: ActorType = .mainActor,
    option: DebounceOptions = .default,
    operation: @escaping () -> Void
) {
    Task {
        await throttler.debounce(
            duration,
            identifier: identifier,
            by: actor,
            option: option,
            operation: operation
        )
    }
}
