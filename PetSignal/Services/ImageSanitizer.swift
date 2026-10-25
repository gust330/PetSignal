import UIKit

enum ImageSanitizer {
    static func sanitizedJPEGData(from data: Data, maxDimension: CGFloat = 1_600) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            return nil
        }

        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { context in
            context.cgContext.setFillColor(UIColor.systemBackground.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
