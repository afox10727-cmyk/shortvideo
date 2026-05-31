import SwiftUI

/// Cached async image loader with disk and memory cache.
/// Falls back to a placeholder during loading and on error.
struct AsyncImageView<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    private static let cache = NSCache<NSURL, UIImage>()

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.white.opacity(0.5))
                        }
                    }
            }
        }
        .task(id: url) { await loadImage() }
    }

    private func loadImage() async {
        guard let url = url else { return }

        // Check memory cache
        if let cached = Self.cache.object(forKey: url as NSURL) {
            await MainActor.run { self.image = cached }
            return
        }

        // Check disk cache
        let diskKey = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? url.absoluteString
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let diskURL = cacheDir.appendingPathComponent("images/\(diskKey)")

        if FileManager.default.fileExists(atPath: diskURL.path),
           let data = try? Data(contentsOf: diskURL),
           let cached = UIImage(data: data) {
            Self.cache.setObject(cached, forKey: url as NSURL)
            await MainActor.run { self.image = cached }
            return
        }

        // Download
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloaded = UIImage(data: data) {
                // Save to memory cache
                Self.cache.setObject(downloaded, forKey: url as NSURL)
                // Save to disk cache
                try? FileManager.default.createDirectory(
                    at: diskURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? data.write(to: diskURL)
                await MainActor.run { self.image = downloaded }
            }
        } catch {
            print("Image load error: \(error)")
        }
    }

    /// Clear all caches
    static func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Convenience initializers

extension AsyncImageView where Placeholder == Color {
    init(url: URL?, contentMode: ContentMode = .fill) {
        self.init(url: url, contentMode: contentMode) {
            Color.white.opacity(0.08)
        }
    }
}

extension AsyncImageView where Placeholder == CircleFillPlaceholder {
    init(url: URL?, size: CGFloat = 44) {
        self.init(url: url, contentMode: .fill) {
            CircleFillPlaceholder(size: size)
        }
    }
}

struct CircleFillPlaceholder: View {
    let size: CGFloat
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.gray)
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        AsyncImageView(url: nil)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        AsyncImageView(url: URL(string: "https://example.com/img.jpg"))
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.black)
}
