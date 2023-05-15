//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

extension STTextView {

    /// Speaks the selected text, or all text if no selection.
    @objc func startSpeaking(_ sender: Any?) {
        stopSpeaking(sender)
        speechSynthesizer.startSpeaking(textLayoutManager.textSelectionsString() ?? string)
    }

    /// Stops the speaking of text.
    @objc func stopSpeaking(_ sender: Any?) {
        guard speechSynthesizer.isSpeaking else {
            return
        }

        speechSynthesizer.stopSpeaking(at: .immediateBoundary)
    }
}
