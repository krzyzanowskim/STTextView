//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import AppKit
import AVFoundation

extension STTextView {

    /// Speaks the selected text, or all text if no selection.
    @objc open func startSpeaking(_ sender: Any?) {
        stopSpeaking(sender)

        let attrString: NSAttributedString
        let selectionTextRanges = textLayoutManager.textSelectionsRanges(.withoutInsertionPoints)
        if selectionTextRanges.isEmpty {
            attrString = attributedString()
        } else {
            attrString = textLayoutManager.textAttributedString(in: selectionTextRanges) ?? NSAttributedString()
        }

        if !attrString.isEmpty {
            let utterance = AVSpeechUtterance(attributedString: attrString)
            utterance.prefersAssistiveTechnologySettings = true
            speechSynthesizer.speak(utterance)
        }
    }

    /// Stops the speaking of text.
    @objc open func stopSpeaking(_ sender: Any?) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .word)
        }
    }
}
