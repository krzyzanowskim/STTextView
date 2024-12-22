import AppKit

extension NSView {
    func stImage() -> NSImage? {
        guard let imageRep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: imageRep)

        guard let cgImage = imageRep.cgImage else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}
