//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import Cocoa

extension STTextView {

    @objc func startSpeaking(_ sender: Any?) {
        guard !NSSpeechSynthesizer.isAnyApplicationSpeaking else {
            return
        }

        speechSynthesizer.startSpeaking(textLayoutManager.textSelectionsString() ?? string)
    }

    @objc func stopSpeaking(_ sender: Any?) {
        guard speechSynthesizer.isSpeaking else {
            return
        }

        speechSynthesizer.stopSpeaking(at: .immediateBoundary)
    }
}
