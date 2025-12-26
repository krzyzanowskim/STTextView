// BSD 3-Clause License
//
// Copyright (c) Marcin Krzyżanowski
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if os(macOS) && !targetEnvironment(macCatalyst)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

extension NSTextLineFragment {

    /// Whether the line fragment is for the extra line fragment at the end of a document.
    ///
    /// The layout manager uses the extra line fragment when the last character in a document causes a line or paragraph break. This extra line fragment has no corresponding glyph.
    public var isExtraLineFragment: Bool {
        // textLineFragment.characterRange.isEmpty the extra line fragment at the end of a document.
        characterRange.isEmpty
    }

    /// Returns a text range inside privided textLayoutFragment.
    ///
    /// Returned range is relative to the document range origin.
    /// - Parameter textLayoutFragment: Text layout fragment
    /// - Returns: Text range or nil
    public func textRange(in textLayoutFragment: NSTextLayoutFragment) -> NSTextRange? {

        guard let textContentManager = textLayoutFragment.textLayoutManager?.textContentManager else {
            assertionFailure()
            return nil
        }

        return NSTextRange(
            location: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location)!,
            end: textContentManager.location(textLayoutFragment.rangeInElement.location, offsetBy: characterRange.location + characterRange.length)
        )
    }
}
