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

        let img = NSImage(cgImage: cgImage, size: bounds.size)
        img.addRepresentation(imageRep)
        return img
    }
}
