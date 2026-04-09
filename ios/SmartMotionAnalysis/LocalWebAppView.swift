import SwiftUI
import UIKit
import WebKit

struct LocalWebAppView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: Coordinator.bridgeName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.webView = webView

        if let htmlURL = Bundle.main.url(forResource: "preview", withExtension: "html", subdirectory: "Resources") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.bridgeName)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        static let bridgeName = "nativeBridge"

        weak var webView: WKWebView?
        private var pendingFiles: [PendingShareFile] = []
        private var sharedItemURLs: [URL] = []

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.bridgeName,
                  let payload = message.body as? [String: Any],
                  let action = payload["action"] as? String else {
                return
            }

            switch action {
            case "shareVideoBegin":
                preparePendingFiles(from: payload)
            case "shareVideoChunk":
                appendChunk(from: payload)
            case "shareVideoComplete":
                sharePendingFiles()
            case "shareScreen":
                shareCurrentScreen()
            default:
                break
            }
        }

        private func preparePendingFiles(from payload: [String: Any]) {
            let files = payload["files"] as? [[String: Any]] ?? []
            pendingFiles = files.map { file in
                PendingShareFile(
                    name: file["name"] as? String ?? "video.mov",
                    mimeType: file["type"] as? String ?? "video/quicktime"
                )
            }
        }

        private func appendChunk(from payload: [String: Any]) {
            guard let fileIndex = payload["fileIndex"] as? Int,
                  pendingFiles.indices.contains(fileIndex),
                  let base64Chunk = payload["chunk"] as? String,
                  let data = Data(base64Encoded: base64Chunk, options: [.ignoreUnknownCharacters]) else {
                return
            }

            pendingFiles[fileIndex].data.append(data)
        }

        private func sharePendingFiles() {
            guard !pendingFiles.isEmpty else { return }

            do {
                sharedItemURLs = try writePendingFilesToTemporaryDirectory()
                presentActivity(items: sharedItemURLs)
            } catch {
                sendStatus("動画共有の準備に失敗しました。")
            }

            pendingFiles.removeAll()
        }

        private func writePendingFilesToTemporaryDirectory() throws -> [URL] {
            let directoryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("smart-motion-share-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            return try pendingFiles.enumerated().map { index, file in
                let baseName = sanitizedFilename(file.name, fallback: "video-\(index + 1).mov")
                let fileURL = directoryURL.appendingPathComponent(baseName)
                try file.data.write(to: fileURL, options: .atomic)
                return fileURL
            }
        }

        private func shareCurrentScreen() {
            guard let webView else { return }

            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = true

            webView.takeSnapshot(with: configuration) { [weak self] image, error in
                guard let self else { return }

                if let image {
                    self.presentActivity(items: [image])
                } else {
                    let message = error == nil ? "画面共有の取得に失敗しました。" : "画面共有の取得に失敗しました。"
                    self.sendStatus(message)
                }
            }
        }

        private func presentActivity(items: [Any]) {
            DispatchQueue.main.async {
                guard let presenter = self.topViewController() else {
                    self.sendStatus("共有画面を開けませんでした。")
                    return
                }

                let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let popover = controller.popoverPresentationController {
                    popover.sourceView = self.webView ?? presenter.view
                    popover.sourceRect = self.webView?.bounds ?? presenter.view.bounds
                }
                presenter.present(controller, animated: true)
            }
        }

        private func topViewController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }

            let root = scenes
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController

            var current = root
            while let presented = current?.presentedViewController {
                current = presented
            }
            return current
        }

        private func sendStatus(_ message: String) {
            let escaped = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            webView?.evaluateJavaScript("window.setNativeStatus && window.setNativeStatus('\(escaped)');")
        }

        private func sanitizedFilename(_ name: String, fallback: String) -> String {
            let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
            let cleaned = name.components(separatedBy: invalidCharacters).joined(separator: "-")
            return cleaned.isEmpty ? fallback : cleaned
        }
    }
}

private struct PendingShareFile {
    let name: String
    let mimeType: String
    var data = Data()
}
