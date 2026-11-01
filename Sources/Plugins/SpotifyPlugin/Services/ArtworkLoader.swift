import AppKit

/// Album artwork via Spotify's public oEmbed endpoint: no Automation permission needed.
/// Keeps the 20 most recent results in memory.
@MainActor
final class ArtworkLoader {
    struct Artwork {
        let image: NSImage
        /// Average colour, lifted so it reads on black.
        let tint: NSColor
    }

    private var cache: [String: Artwork] = [:]
    private var recency: [String] = []
    private let capacity = 20

    func artwork(for trackID: String) async -> Artwork? {
        if let hit = cache[trackID] {
            touch(trackID)
            return hit
        }
        guard let artwork = await Self.download(trackID) else { return nil }
        insert(artwork, for: trackID)
        return artwork
    }

    // MARK: - LRU

    private func touch(_ key: String) {
        recency.removeAll { $0 == key }
        recency.append(key)
    }

    private func insert(_ artwork: Artwork, for key: String) {
        cache[key] = artwork
        touch(key)
        if recency.count > capacity { cache[recency.removeFirst()] = nil }
    }

    // MARK: - Network

    /// oEmbed JSON → `thumbnail_url` → image bytes.
    private nonisolated static func download(_ trackID: String) async -> Artwork? {
        guard let metadataURL = oEmbedURL(for: trackID),
              let (metadata, _) = try? await URLSession.shared.data(from: metadataURL),
              let json = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any],
              let thumbnailURL = (json["thumbnail_url"] as? String).flatMap(URL.init(string:)),
              let (bytes, _) = try? await URLSession.shared.data(from: thumbnailURL),
              let image = NSImage(data: bytes) else { return nil }
        return Artwork(image: ArtworkImage.downscaled(image, toPixels: 160), tint: ArtworkImage.readableTint(of: image))
    }

    private nonisolated static func oEmbedURL(for trackID: String) -> URL? {
        let bareID = trackID.replacingOccurrences(of: "spotify:track:", with: "")
        guard !bareID.isEmpty, !bareID.contains(":") else { return nil } // local files, podcasts, ads
        var components = URLComponents(string: "https://open.spotify.com/oembed")
        components?.queryItems = [URLQueryItem(name: "url", value: "https://open.spotify.com/track/\(bareID)")]
        return components?.url
    }
}

/// Pure image helpers: Core Graphics only, no Core Image.
enum ArtworkImage {
    /// Keeps memory flat: Spotify thumbnails are 300 px, and we never draw above 80 pt @2x.
    static func downscaled(_ image: NSImage, toPixels side: Int) -> NSImage {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let context = CGContext(
                  data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return image }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let scaled = context.makeImage() else { return image }
        return NSImage(cgImage: scaled, size: NSSize(width: side / 2, height: side / 2))
    }

    /// Average colour (drawn into a 1×1 bitmap), with saturation boosted and brightness ≥ 0.75.
    static func readableTint(of image: NSImage) -> NSColor {
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let context = CGContext(
                  data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return .white }
        context.interpolationQuality = .medium
        context.draw(source, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        let average = NSColor(srgbRed: CGFloat(pixel[0]) / 255, green: CGFloat(pixel[1]) / 255,
                              blue: CGFloat(pixel[2]) / 255, alpha: 1)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        average.usingColorSpace(.sRGB)?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return NSColor(hue: hue, saturation: min(1, saturation * 1.2), brightness: max(brightness, 0.75), alpha: 1)
    }
}
